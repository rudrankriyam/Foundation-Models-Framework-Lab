import Foundation
import NIOCore
import NIOEmbedded
import NIOHTTP1
import Testing
@testable import AFMServer

@Test("Health and model discovery use the injected catalog and clock")
func healthAndModels() throws {
    let catalog = AFMStaticModelCatalog(
        models: [
            .init(id: "system", isAvailable: true),
            .init(id: "adapter-demo", isAvailable: false, owner: "local")
        ]
    )
    let router = AFMRequestRouter(
        configuration: .init(),
        catalog: catalog,
        clock: TestClock(value: 1_234)
    )

    let health = try performRequest(path: "/health", router: router)
    #expect(health.head.status == .ok)
    let healthJSON = try jsonObject(health.body)
    #expect(healthJSON["status"] as? String == "afm serve is running")
    let healthModels = try #require(healthJSON["models"] as? [[String: Any]])
    #expect(healthModels.map { $0["name"] as? String } == ["adapter-demo", "system"])
    #expect(healthModels[0]["available"] as? Bool == false)

    let models = try performRequest(path: "/v1/models?ignored=true", router: router)
    #expect(models.head.status == .ok)
    let modelsJSON = try jsonObject(models.body)
    let modelData = try #require(modelsJSON["data"] as? [[String: Any]])
    #expect(modelData.map { $0["id"] as? String } == ["adapter-demo", "system"])
    #expect(modelData.allSatisfy { $0["created"] as? Int == 1_234 })
    #expect(modelData[0]["owned_by"] as? String == "local")
}

@Test("Unknown routes and wrong methods return JSON API errors")
func routingErrors() throws {
    let router = testRouter()

    let missing = try performRequest(path: "/missing", router: router)
    #expect(missing.head.status == .notFound)
    #expect(try errorCode(missing.body) == "not_found")

    let wrongMethod = try performRequest(method: .POST, path: "/health", router: router)
    #expect(wrongMethod.head.status == .methodNotAllowed)
    #expect(wrongMethod.head.headers.first(name: "allow") == "GET")
    #expect(try errorCode(wrongMethod.body) == "method_not_allowed")
}

@Test("Loopback Host and Origin policies reject cross-site requests by default")
func hostAndOriginPolicy() throws {
    let router = testRouter()

    let hostileHost = try performRequest(path: "/health", host: "example.com", router: router)
    #expect(hostileHost.head.status == .forbidden)
    #expect(try errorCode(hostileHost.body) == "forbidden_host")

    let hostileOrigin = try performRequest(
        path: "/health",
        additionalHeaders: [("origin", "https://example.com")],
        router: router
    )
    #expect(hostileOrigin.head.status == .forbidden)
    #expect(try errorCode(hostileOrigin.body) == "origin_not_allowed")

    let allowedRouter = testRouter(allowedOrigins: ["https://trusted.example"])
    let allowed = try performRequest(
        path: "/health",
        additionalHeaders: [("origin", "https://trusted.example")],
        router: allowedRouter
    )
    #expect(allowed.head.status == .ok)
    #expect(allowed.head.headers.first(name: "access-control-allow-origin") == "https://trusted.example")
    #expect(allowed.head.headers.first(name: "vary") == "Origin")
}

@Test("Bearer authentication protects every route when configured")
func bearerAuthentication() throws {
    let router = testRouter(token: "correct-token", allowedOrigins: ["https://trusted.example"])

    let missing = try performRequest(
        path: "/health",
        additionalHeaders: [("origin", "https://trusted.example")],
        router: router
    )
    #expect(missing.head.status == .unauthorized)
    #expect(missing.head.headers.first(name: "www-authenticate") == "Bearer")
    #expect(missing.head.headers.first(name: "access-control-allow-origin") == "https://trusted.example")
    #expect(missing.head.headers.first(name: "vary") == "Origin")

    let incorrect = try performRequest(
        path: "/health",
        additionalHeaders: [("authorization", "Bearer incorrect-token")],
        router: router
    )
    #expect(incorrect.head.status == .unauthorized)

    let valid = try performRequest(
        path: "/health",
        additionalHeaders: [("authorization", "bearer correct-token")],
        router: router
    )
    #expect(valid.head.status == .ok)
}

@Test("Body and media-type limits produce deterministic JSON errors")
func bodyAndMediaTypeLimits() throws {
    let limits = AFMServerLimits(maximumBodyBytes: 4)
    let router = testRouter(limits: limits)

    let exactLimit = try performRequest(
        path: "/health",
        body: Data("1234".utf8),
        contentType: "application/json; charset=utf-8",
        router: router,
        limits: limits
    )
    #expect(exactLimit.head.status == .ok)

    let tooLarge = try performRequest(
        path: "/health",
        body: Data("12345".utf8),
        contentType: "application/json",
        router: router,
        limits: limits
    )
    #expect(tooLarge.head.status == .payloadTooLarge)
    #expect(try errorCode(tooLarge.body) == "request_too_large")

    let enormousDeclaration = try performRequest(
        path: "/health",
        additionalHeaders: [
            ("content-length", String(UInt64.max)),
            ("content-type", "application/json")
        ],
        router: router,
        limits: limits
    )
    #expect(enormousDeclaration.head.status == .payloadTooLarge)

    let unsupported = try performRequest(
        path: "/health",
        body: Data("1".utf8),
        contentType: "text/plain",
        router: router,
        limits: limits
    )
    #expect(unsupported.head.status == .unsupportedMediaType)
    #expect(try errorCode(unsupported.body) == "unsupported_media_type")
}

@Test("Header overflow becomes a JSON 431 response")
func headerOverflow() throws {
    let channel = EmbeddedChannel(handler: AFMHTTPHandler(router: testRouter(), limits: .init()))
    channel.pipeline.fireErrorCaught(HTTPParserError.headerOverflow)

    let response = try readResponse(from: channel)
    #expect(response.head.status.code == 431)
    #expect(response.head.status.reasonPhrase == "Request Header Fields Too Large")
    #expect(try errorCode(response.body) == "headers_too_large")
    _ = try? channel.finish()
}

@Test("Keep-alive connections reset request state between requests")
func keepAliveRequests() throws {
    let channel = EmbeddedChannel(handler: AFMHTTPHandler(router: testRouter(), limits: .init()))
    try writeRequest(path: "/health", to: channel)
    let first = try readResponse(from: channel)
    try writeRequest(path: "/v1/models", to: channel)
    let second = try readResponse(from: channel)

    #expect(first.head.status == .ok)
    #expect(second.head.status == .ok)
    _ = try? channel.finish()
}

private struct TestClock: AFMServerClock {
    let value: Int64

    func unixTime() -> Int64 { value }
}

private struct TestHTTPResponse {
    let head: HTTPResponseHead
    let body: Data
}

private func testRouter(
    token: String? = nil,
    allowedOrigins: Set<String> = [],
    limits: AFMServerLimits = .init()
) -> AFMRequestRouter {
    AFMRequestRouter(
        configuration: .init(
            limits: limits,
            security: .init(bearerToken: token, allowedOrigins: allowedOrigins)
        ),
        catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
        clock: TestClock(value: 123)
    )
}

private func performRequest(
    method: HTTPMethod = .GET,
    path: String,
    host: String = "127.0.0.1:1976",
    additionalHeaders: [(String, String)] = [],
    body: Data? = nil,
    contentType: String? = nil,
    router: AFMRequestRouter,
    limits: AFMServerLimits = .init()
) throws -> TestHTTPResponse {
    let channel = EmbeddedChannel(handler: AFMHTTPHandler(router: router, limits: limits))
    try writeRequest(
        method: method,
        path: path,
        host: host,
        additionalHeaders: additionalHeaders,
        body: body,
        contentType: contentType,
        to: channel
    )
    let response = try readResponse(from: channel)
    _ = try? channel.finish()
    return response
}

private func writeRequest(
    method: HTTPMethod = .GET,
    path: String,
    host: String = "127.0.0.1:1976",
    additionalHeaders: [(String, String)] = [],
    body: Data? = nil,
    contentType: String? = nil,
    to channel: EmbeddedChannel
) throws {
    var headers = HTTPHeaders()
    headers.add(name: "host", value: host)
    for (name, value) in additionalHeaders {
        headers.add(name: name, value: value)
    }
    if let body {
        headers.add(name: "content-length", value: String(body.count))
    }
    if let contentType {
        headers.add(name: "content-type", value: contentType)
    }

    let head = HTTPRequestHead(version: .http1_1, method: method, uri: path, headers: headers)
    try channel.writeInbound(HTTPServerRequestPart.head(head))
    if let body {
        var buffer = channel.allocator.buffer(capacity: body.count)
        buffer.writeBytes(body)
        try channel.writeInbound(HTTPServerRequestPart.body(buffer))
    }
    try channel.writeInbound(HTTPServerRequestPart.end(nil))
}

private func readResponse(from channel: EmbeddedChannel) throws -> TestHTTPResponse {
    var responseHead: HTTPResponseHead?
    var responseBody = Data()

    while let part = try channel.readOutbound(as: HTTPServerResponsePart.self) {
        switch part {
        case .head(let head):
            responseHead = head
        case .body(.byteBuffer(var buffer)):
            if let bytes = buffer.readBytes(length: buffer.readableBytes) {
                responseBody.append(contentsOf: bytes)
            }
        case .body(.fileRegion):
            Issue.record("Unexpected file-region response body")
        case .end:
            return TestHTTPResponse(head: try #require(responseHead), body: responseBody)
        }
    }
    throw TestResponseError.missingEnd
}

private func jsonObject(_ data: Data) throws -> [String: Any] {
    try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
}

private func errorCode(_ data: Data) throws -> String? {
    let object = try jsonObject(data)
    let error = try #require(object["error"] as? [String: Any])
    return error["code"] as? String
}

private enum TestResponseError: Error {
    case missingEnd
}
