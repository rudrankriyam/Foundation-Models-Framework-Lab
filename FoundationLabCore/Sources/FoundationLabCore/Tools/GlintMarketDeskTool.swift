import Foundation
import FoundationModels

/// Reads one stored Glint candle. The reply contains only fields from that read.
public struct GlintMarketDeskTool: Tool, Sendable {
    public let name = "glintMarketDesk"
    public let description = "Reads the stored NIFTY 50 5-minute bar from Glint. Returns that bar or a gap. Does not calculate a spot, EMA, ATR, or RRS."

    @Generable
    public struct Arguments: Sendable {
        @Guide(description: "NIFTY 50. Other symbols are a gap and have no price.")
        public var symbol: String

        public init(symbol: String = "NIFTY 50") {
            self.symbol = symbol
        }
    }

    private let load: @Sendable (URLRequest) async throws -> (Int, Data)

    public init() {
        self.init(load: Self.urlSessionLoad)
    }

    init(load: @escaping @Sendable (URLRequest) async throws -> (Int, Data)) {
        self.load = load
    }

    public func call(arguments: Arguments) async throws -> String {
        let symbol = arguments.symbol.trimmingCharacters(in: .whitespacesAndNewlines)
        switch GlintStoredBarRead.plan(symbol: symbol, environment: ProcessInfo.processInfo.environment) {
        case .unsupported:
            return GlintStoredBarRead.unsupported(symbol: symbol)
        case .missingToken:
            return GlintStoredBarRead.missingToken()
        case .request(let request):
            return try await loadRead(request)
        }
    }

    private func loadRead(_ request: URLRequest) async throws -> String {
        do {
            let (status, body) = try await load(request)
            return GlintStoredBarRead.text(statusCode: status, body: body)
        } catch {
            return GlintStoredBarRead.transportFailure()
        }
    }

    private static func urlSessionLoad(_ request: URLRequest) async throws -> (Int, Data) {
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        return (status, data)
    }
}

enum GlintStoredBarRead {
    static let endpoint = URL(string: "https://tradeshot.co/v2/market/candles")!

    enum Plan {
        case unsupported
        case missingToken
        case request(URLRequest)
    }

    static func plan(symbol: String, environment: [String: String], allowDiskFallback: Bool = true) -> Plan {
        guard isNifty(symbol) else { return .unsupported }
        guard let token = readToken(environment: environment, allowDiskFallback: allowDiskFallback) else { return .missingToken }
        guard let request = makeRequest(token: token) else { return .missingToken }
        return .request(request)
    }

    static func missingToken() -> String {
        gap("cloud_read_token_missing")
    }

    private static func makeRequest(token: String) -> URLRequest? {
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "kite"),
            URLQueryItem(name: "exchange", value: "NSE"),
            URLQueryItem(name: "segment", value: "nse"),
            URLQueryItem(name: "timeframe", value: "5m"),
            URLQueryItem(name: "instrument", value: "NIFTY 50"),
            URLQueryItem(name: "provider_token", value: "256265"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components?.url else { return nil }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("GlintFoundationLab/1.0", forHTTPHeaderField: "User-Agent")
        return request
    }

    static func unsupported(symbol: String) -> String {
        """
        Glint stored bar
        symbol=\(symbol)
        timeframe=5m
        status=unavailable
        rows=0
        gap=symbol_not_in_this_read
        orders=locked
        """
    }

    static func text(statusCode: Int, body: Data) -> String {
        if statusCode == 401 || statusCode == 403 {
            return gap("cloud_read_unauthorized")
        }
        guard (200..<300).contains(statusCode),
              let envelope = try? JSONDecoder().decode(Envelope.self, from: body),
              envelope.schema == "glint.market.v2", envelope.ordersLocked, !envelope.mutation,
              envelope.provider == "kite", envelope.timeframe == "5m",
              envelope.instrument.symbol == "NIFTY 50", envelope.instrument.exchange == "NSE",
              envelope.instrument.instrumentID == "256265" else {
            return gap("cloud_read_unreadable")
        }
        var lines = [
            "Glint stored bar", "symbol=\(envelope.instrument.symbol)", "timeframe=\(envelope.timeframe)",
            "status=\(envelope.status.rawValue)", "completeness=\(envelope.snapshot.completeness.rawValue)",
            "rows=\(envelope.candles.count)", "snapshot=\(envelope.snapshot.id)",
            "source=\(envelope.source)", "updateStatus=\(envelope.snapshot.updateStatus.rawValue)",
            "retrievedAt=\(envelope.snapshot.retrievedAt)", "priceKind=stored_candle_not_live_spot"
        ]
        for reason in envelope.gaps ?? [] { lines.append("gap=\(reason)") }
        if envelope.candles.isEmpty {
            if envelope.gaps?.isEmpty != false { lines.append("gap=series_not_stored") }
        } else {
            guard envelope.status != .unavailable, envelope.snapshot.completeness != .unavailable,
                  !envelope.snapshot.id.isEmpty, envelope.source == "kite:nse",
                  envelope.origin?.source == envelope.source,
                  envelope.origin?.retrievedAt == envelope.snapshot.retrievedAt,
                  envelope.coverage?.snapshotID == envelope.snapshot.id,
                  parsedDate(envelope.snapshot.retrievedAt) != nil,
                  envelope.candles.allSatisfy({ candle in
                      parsedDate(candle.timestamp) != nil && candle.low <= candle.high &&
                      candle.close >= candle.low && candle.close <= candle.high &&
                      candle.open >= candle.low && candle.open <= candle.high && candle.volume >= 0
                  }) else { return gap("cloud_read_unreadable") }
            let closed = envelope.candles.filter { $0.state == .closed }
            if let row = closed.max(by: { parsedDate($0.timestamp)! < parsedDate($1.timestamp)! }) {
                lines += ["candleOpenedAt=\(row.timestamp)", "open=\(row.open)", "high=\(row.high)",
                          "low=\(row.low)", "close=\(row.close)", "volume=\(row.volume)", "state=closed"]
            } else {
                lines.append("gap=closed_candle_unavailable")
            }
        }
        lines.append("orders=locked")
        return lines.joined(separator: "\n")
    }

    private static func parsedDate(_ text: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: text) ?? ISO8601DateFormatter().date(from: text)
    }

    private struct Envelope: Decodable {
        enum Status: String, Decodable { case ok, partial, unavailable }
        struct Instrument: Decodable {
            let symbol: String
            let exchange: String
            let instrumentID: String
            enum CodingKeys: String, CodingKey { case symbol, exchange; case instrumentID = "instrument_id" }
        }
        struct Snapshot: Decodable {
            enum Completeness: String, Decodable { case complete, partial, unavailable }
            enum UpdateStatus: String, Decodable { case current, stale, updating, unavailable }
            let id: String
            let completeness: Completeness
            let updateStatus: UpdateStatus
            let retrievedAt: String
            enum CodingKeys: String, CodingKey {
                case id, completeness
                case updateStatus = "update_status"
                case retrievedAt = "retrieved_at"
            }
        }
        struct Origin: Decodable {
            let source: String
            let retrievedAt: String
            enum CodingKeys: String, CodingKey { case source; case retrievedAt = "retrieved_at" }
        }
        struct Coverage: Decodable {
            let snapshotID: String
            enum CodingKeys: String, CodingKey { case snapshotID = "snapshot_id" }
        }
        struct Candle: Decodable {
            enum State: String, Decodable { case closed, forming, open, unknown }
            let timestamp: String
            let open: Decimal
            let high: Decimal
            let low: Decimal
            let close: Decimal
            let volume: Decimal
            let state: State
        }
        let schema: String
        let status: Status
        let provider: String
        let timeframe: String
        let instrument: Instrument
        let ordersLocked: Bool
        let mutation: Bool
        let snapshot: Snapshot
        let source: String
        let origin: Origin?
        let coverage: Coverage?
        let gaps: [String]?
        let candles: [Candle]
        enum CodingKeys: String, CodingKey {
            case schema, status, provider, timeframe, instrument, ordersLocked, mutation, snapshot, origin, coverage, candles
            case source = "source_identity"
            case gaps = "typed_gaps"
        }
    }

    static func transportFailure() -> String {
        gap("cloud_read_failed")
    }

    private static func gap(_ reason: String) -> String {
        """
        Glint stored bar
        symbol=NIFTY 50
        timeframe=5m
        status=unavailable
        rows=0
        gap=\(reason)
        orders=locked
        """
    }

    private static func isNifty(_ symbol: String) -> Bool {
        switch symbol.uppercased().replacingOccurrences(of: " ", with: "") {
        case "NIFTY", "NIFTY50", "^NSEI":
            true
        default:
            false
        }
    }

    private static func readToken(environment: [String: String], allowDiskFallback: Bool = true) -> String? {
        if let val = environment["GLINT_CLOUD_READ_TOKEN"] ?? environment["GLINT_VPS_READ_TOKEN"] {
            let trimmed = val.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        guard allowDiskFallback else { return nil }
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let tokenFile = support.appendingPathComponent("GlintSwift/cloud-read-token.json")
        if let data = try? Data(contentsOf: tokenFile),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let token = json["token"] as? String, !token.isEmpty {
            return token
        }
        return nil
    }

}
