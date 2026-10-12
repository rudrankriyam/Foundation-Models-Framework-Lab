import Foundation
import XCTest
@testable import FoundationLabCore

final class GlintOptionChainTruthTests: XCTestCase {
    func testSpotQuoteCannotBecomeOptionOpenInterest() async throws {
        URLProtocol.registerClass(SpotQuoteProtocol.self)
        defer { URLProtocol.unregisterClass(SpotQuoteProtocol.self) }
        let text = try await GlintOptionChainTool().call(arguments: .init(underlying: "NIFTY"))
        XCTAssertTrue(text.contains("gap=option_chain_not_connected"))
        XCTAssertFalse(text.contains("1.05"))
        XCTAssertFalse(text.contains("Heavy Call Writing"))
        XCTAssertFalse(text.contains("Live Option Chain"))
    }
}

private final class SpotQuoteProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let body = Data(#"{"chart":{"result":[{"meta":{"regularMarketPrice":22363.35}}]}}"#.utf8)
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
