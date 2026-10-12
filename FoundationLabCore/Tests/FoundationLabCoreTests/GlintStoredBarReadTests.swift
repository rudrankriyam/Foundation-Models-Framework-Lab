import XCTest
@testable import FoundationLabCore

final class GlintStoredBarReadTests: XCTestCase {
    func testStoredEnvelopeRepeatsTheBarAndNoOtherSpot() {
        let body = envelope()
        let text = GlintStoredBarRead.text(statusCode: 200, body: body)

        XCTAssertTrue(text.contains("close=22363.35"), text)
        XCTAssertTrue(text.contains("candleOpenedAt=2026-10-12T09:55:00.000Z"))
        XCTAssertTrue(text.contains("rows=1"))
        XCTAssertFalse(text.contains("22145"))
        XCTAssertFalse(text.contains("25145"))
        XCTAssertFalse(text.contains("25,145"))
    }

    func testMissingTokenAndUnauthorizedNameAGap() {
        let missing = GlintStoredBarRead.plan(symbol: "NIFTY 50", environment: [:], allowDiskFallback: false)
        if case .missingToken = missing {} else {
            XCTFail("expected a missing token")
        }
        let missingText = GlintStoredBarRead.missingToken()
        XCTAssertTrue(missingText.contains("gap=cloud_read_token_missing"))
        XCTAssertFalse(missingText.contains("close="))

        let denied = GlintStoredBarRead.text(statusCode: 401, body: Data("{\"status\":\"401\"}".utf8))
        XCTAssertTrue(denied.contains("gap=cloud_read_unauthorized"))
        XCTAssertFalse(denied.contains("close="))
        XCTAssertFalse(denied.contains("22145"))
    }

    func testV2EnvelopePreservesEvidenceAndDoesNotAssumeCompleteness() {
        let body = envelope { object in
            object["candles"] = []
            object["typed_gaps"] = ["coverage_incomplete"]
            var snapshot = object["snapshot"] as! [String: Any]
            snapshot["completeness"] = "partial"
            snapshot["update_status"] = "stale"
            object["snapshot"] = snapshot
        }
        let text = GlintStoredBarRead.text(statusCode: 200, body: body)
        XCTAssertTrue(text.contains("snapshot=snapshot-1"))
        XCTAssertTrue(text.contains("source=kite:nse"))
        XCTAssertTrue(text.contains("updateStatus=stale"))
        XCTAssertTrue(text.contains("coverage_incomplete"))
        XCTAssertFalse(text.contains("close="))
    }

    func testUnsafeEnvelopeCannotYieldAPriceOrClaimLocked() {
        let body = Data("""
        {"schema":"glint.market.v2","ordersLocked":false,"mutation":true,
         "instrument":{"symbol":"NIFTY 50"},"timeframe":"5m","status":"ok",
         "snapshot":{"completeness":"complete"},"candles":[{"close":22363.35,"state":"forming"}]}
        """.utf8)
        let text = GlintStoredBarRead.text(statusCode: 200, body: body)
        XCTAssertTrue(text.contains("gap=cloud_read_unreadable"))
        XCTAssertFalse(text.contains("close="))
    }

    func testRejectsEachBrokenSafetyAndEvidenceField() {
        for field in ["ordersLocked", "mutation", "schema", "snapshot", "origin", "coverage"] {
            let body = envelope { object in
                switch field {
                case "ordersLocked": object[field] = false
                case "mutation": object[field] = true
                case "schema": object[field] = "unknown"
                default: object.removeValue(forKey: field)
                }
            }
            let text = GlintStoredBarRead.text(statusCode: 200, body: body)
            XCTAssertTrue(text.contains("gap=cloud_read_unreadable"), field)
            XCTAssertFalse(text.contains("close="), field)
        }
    }

    func testMissingCloseCannotYieldAPrice() {
        let body = envelope { object in
            var bars = object["candles"] as! [[String: Any]]
            bars[0].removeValue(forKey: "close")
            object["candles"] = bars
        }
        XCTAssertTrue(GlintStoredBarRead.text(statusCode: 200, body: body).contains("gap=cloud_read_unreadable"))
    }

    func testFormingCandleDoesNotReplaceLastClosedCandle() {
        let body = envelope { object in
            var bars = object["candles"] as! [[String: Any]]
            var forming = bars[0]
            forming["timestamp"] = "2026-10-12T10:00:00.000Z"
            forming["state"] = "forming"
            forming["close"] = 22330
            bars.append(forming)
            object["candles"] = bars
        }
        let text = GlintStoredBarRead.text(statusCode: 200, body: body)
        XCTAssertTrue(text.contains("close=22363.35"), text)
        XCTAssertTrue(text.contains("candleOpenedAt=2026-10-12T09:55:00.000Z"))
        XCTAssertFalse(text.contains("close=22330"))
    }

    func testOpenAndUnknownBarsDoNotSuppressClosedBar() {
        for state in ["open", "unknown"] {
            let body = envelope { object in
                var bars = object["candles"] as! [[String: Any]]
                var bar = bars[0]
                bar["state"] = state
                bar["timestamp"] = "2026-10-12T10:00:00.000Z"
                bars.append(bar)
                object["candles"] = bars
            }
            let text = GlintStoredBarRead.text(statusCode: 200, body: body)
            XCTAssertTrue(text.contains("candleOpenedAt=2026-10-12T09:55:00.000Z"), text)
        }
    }

    func testMismatchedOriginCannotYieldAPrice() {
        let body = envelope { object in
            object["origin"] = ["source": "kite:nse", "retrieved_at": "2026-10-11T10:01:00.000Z"]
        }
        let text = GlintStoredBarRead.text(statusCode: 200, body: body)
        XCTAssertTrue(text.contains("gap=cloud_read_unreadable"))
        XCTAssertFalse(text.contains("close="))
    }

    private func envelope(_ change: (inout [String: Any]) -> Void = { _ in }) -> Data {
        let data = Data("""
        {"schema":"glint.market.v2","status":"ok","provider":"kite","timeframe":"5m",
         "instrument":{"symbol":"NIFTY 50","exchange":"NSE","instrument_id":"256265"},
         "ordersLocked":true,"mutation":false,"source_identity":"kite:nse",
         "snapshot":{"id":"snapshot-1","completeness":"complete","update_status":"current",
                     "retrieved_at":"2026-10-12T10:01:00.000Z"},
         "origin":{"source":"kite:nse","retrieved_at":"2026-10-12T10:01:00.000Z"},"coverage":{"snapshot_id":"snapshot-1"},
         "candles":[{"timestamp":"2026-10-12T09:55:00.000Z","open":22316.85,"high":22363.35,
                     "low":22316.85,"close":22363.35,"volume":0,"state":"closed"}]}
        """.utf8)
        var object = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        var bars = object["candles"] as! [[String: Any]]
        for (key, value) in [("open", "22316.85"), ("low", "22316.85"), ("high", "22363.35"), ("close", "22363.35")] {
            bars[0][key] = NSDecimalNumber(string: value)
        }
        object["candles"] = bars
        change(&object)
        return try! JSONSerialization.data(withJSONObject: object)
    }

    func testOtherSymbolIsAGap() {
        let plan = GlintStoredBarRead.plan(symbol: "RELIANCE", environment: ["GLINT_CLOUD_READ_TOKEN": "present"])
        if case .unsupported = plan {} else {
            XCTFail("expected an unsupported symbol")
        }
        let text = GlintStoredBarRead.unsupported(symbol: "RELIANCE")
        XCTAssertTrue(text.contains("gap=symbol_not_in_this_read"))
        XCTAssertFalse(text.contains("close="))
        XCTAssertFalse(text.contains("3054"))
    }
}
