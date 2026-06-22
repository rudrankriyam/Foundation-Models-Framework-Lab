import Darwin
import Foundation
import FoundationModelsKit
import Testing
@testable import AFMServer

@Test("Bridge client authenticates health, models, and chat requests")
func bridgeClientAuthenticatedRoundTrip() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(token: token)

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: token
        )
        let client = try AFMBridgeClient(descriptor: descriptor)

        let health = try await client.health()
        #expect(health.statusCode == 200)
        #expect(try JSONSerialization.jsonObject(with: health.body) is [String: Any])

        let models = try await client.models()
        #expect(models.statusCode == 200)
        let modelsBody = try #require(String(data: models.body, encoding: .utf8))
        #expect(modelsBody.contains(#""id":"system""#))

        let request = Data(#"{"model":"system","messages":[{"role":"user","content":"Hi"}]}"#.utf8)
        let completion = try await client.chatCompletions(body: request)
        #expect(completion.statusCode == 200)
        let completionBody = try #require(String(data: completion.body, encoding: .utf8))
        #expect(completionBody.contains(#""content":"From bridge client""#))

        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Descriptor-store initialization reads the secure published descriptor")
func bridgeClientDescriptorStoreInitialization() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(token: token)
    let directory = try makeBridgeClientTemporaryDirectory()
    defer { try? FileManager.default.removeItem(atPath: directory) }

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: token
        )
        let store = try AFMBridgeDescriptorStore(directoryPath: directory)
        let lease = try store.publish(descriptor)
        defer { try? lease.cleanup() }

        let response = try await AFMBridgeClient(descriptorStore: store).health()
        #expect(response.statusCode == 200)
        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Bridge client preserves non-success status and API error bodies")
func bridgeClientPreservesAPIError() async throws {
    let serverToken = try AFMBridgeBearerTokenGenerator.generate()
    let clientToken = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(token: serverToken)

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: clientToken
        )
        let response = try await AFMBridgeClient(descriptor: descriptor).health()

        #expect(response.statusCode == 401)
        let errorBody = try #require(String(data: response.body, encoding: .utf8))
        #expect(errorBody.contains(#""code":"invalid_api_key""#))
        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Bridge client reports a stopped descriptor endpoint as a transport failure")
func bridgeClientRejectsStaleEndpoint() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(token: token)
    let port = try await startTCPServer(server)
    try await server.stop()

    let descriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
        token: token
    )
    let configuration = AFMBridgeClientConfiguration(requestTimeout: 0.25)
    let client = try AFMBridgeClient(descriptor: descriptor, configuration: configuration)

    do {
        _ = try await client.health()
        Issue.record("Expected the stale endpoint to fail")
    } catch let error as AFMBridgeClientError {
        guard case .transportFailure = error else {
            Issue.record("Expected a transport failure, got \(error)")
            return
        }
    }
}

@Test("Bridge client rejects unsupported and non-loopback endpoints")
func bridgeClientEndpointValidation() throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let unixDescriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .unixSocket(path: "/tmp/foundation-lab.sock"),
        token: token
    )
    #expect(throws: AFMBridgeClientError.unsupportedTransport) {
        try AFMBridgeClient(descriptor: unixDescriptor)
    }

    let networkDescriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "192.0.2.1", port: 19_760),
        token: token
    )
    #expect(throws: AFMBridgeDescriptorError.invalidField("endpoint.loopbackTCP.host")) {
        try AFMBridgeClient(descriptor: networkDescriptor)
    }
}

@Test("Bridge client validates timeout and response limits")
func bridgeClientConfigurationValidation() throws {
    let descriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "127.0.0.1", port: 19_760)
    )
    #expect(throws: AFMBridgeClientError.invalidConfiguration(field: "requestTimeout")) {
        try AFMBridgeClient(
            descriptor: descriptor,
            configuration: .init(requestTimeout: .nan)
        )
    }
    #expect(throws: AFMBridgeClientError.invalidConfiguration(field: "maximumResponseByteCount")) {
        try AFMBridgeClient(
            descriptor: descriptor,
            configuration: .init(maximumResponseByteCount: 0)
        )
    }
}

@Test("Bridge client enforces its response limit")
func bridgeClientResponseLimit() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(token: token)

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: token
        )
        let client = try AFMBridgeClient(
            descriptor: descriptor,
            configuration: .init(maximumResponseByteCount: 16)
        )

        await #expect(throws: AFMBridgeClientError.responseTooLarge(maximumByteCount: 16)) {
            try await client.health()
        }
        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Stream accumulation enforces its hard cap without Content-Length")
func bridgeClientStreamResponseLimit() async {
    let bytes = AsyncStream<UInt8> { continuation in
        for byte in 0..<32 {
            continuation.yield(UInt8(byte))
        }
        continuation.finish()
    }

    await #expect(throws: AFMBridgeClientError.responseTooLarge(maximumByteCount: 16)) {
        try await AFMBridgeResponseAccumulator.data(from: bytes, maximumByteCount: 16)
    }
}

@Test("Bridge client maps URLSession timeout without exposing its request")
func bridgeClientTimeout() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let server = try makeBridgeClientTestServer(
        token: token,
        generator: BridgeClientPausingGenerator()
    )

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: token
        )
        let client = try AFMBridgeClient(
            descriptor: descriptor,
            configuration: .init(requestTimeout: 0.1)
        )
        let body = Data(#"{"messages":[{"role":"user","content":"Wait"}]}"#.utf8)

        await #expect(throws: AFMBridgeClientError.transportFailure(code: .timedOut)) {
            try await client.chatCompletions(body: body)
        }
        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Cancelling a bridge request surfaces CancellationError")
func bridgeClientCancellation() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let probe = BridgeClientGenerationProbe()
    let server = try makeBridgeClientTestServer(
        token: token,
        generator: BridgeClientPausingGenerator(probe: probe)
    )

    do {
        let port = try await startTCPServer(server)
        let descriptor = try makeAFMBridgeTestDescriptor(
            endpoint: .loopbackTCP(host: "127.0.0.1", port: port),
            token: token
        )
        let client = try AFMBridgeClient(descriptor: descriptor)
        let body = Data(#"{"messages":[{"role":"user","content":"Wait"}]}"#.utf8)
        let request = Task { try await client.chatCompletions(body: body) }

        await probe.waitUntilStarted()
        request.cancel()
        do {
            _ = try await request.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            // Expected.
        } catch {
            Issue.record("Expected CancellationError, got \(error)")
        }
        try? await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

@Test("Bridge client descriptions and reflection redact the bearer token")
func bridgeClientRedactsBearerToken() throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let descriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "127.0.0.1", port: 19_760),
        token: token
    )
    let client = try AFMBridgeClient(descriptor: descriptor)
    var dumpOutput = ""
    dump(client, to: &dumpOutput)

    #expect(!String(describing: client).contains(token))
    #expect(!String(reflecting: client).contains(token))
    #expect(!dumpOutput.contains(token))
    #expect(String(describing: client).contains("<redacted>"))
}

@Test("Bridge client refuses redirects before forwarding authorization")
func bridgeClientRefusesRedirects() async throws {
    let token = try AFMBridgeBearerTokenGenerator.generate()
    let redirectServer = try BridgeClientRedirectServer.start()
    let descriptor = try makeAFMBridgeTestDescriptor(
        endpoint: .loopbackTCP(host: "127.0.0.1", port: redirectServer.port),
        token: token
    )

    let response = try await AFMBridgeClient(descriptor: descriptor).health()
    let requests = try await redirectServer.requests.value

    #expect(response.statusCode == 302)
    #expect(requests.count == 1)
    #expect(requests[0].contains("Authorization: Bearer \(token)"))
}

private func makeBridgeClientTestServer(
    token: String,
    generator: any AFMChatCompletionGenerating = BridgeClientTestGenerator()
) throws -> AFMHTTPServer {
    try AFMHTTPServer(
        configuration: .init(
            endpoint: .tcp(host: "127.0.0.1", port: 0),
            security: .init(bearerToken: token)
        ),
        catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
        clock: BridgeClientTestClock(),
        generator: generator
    )
}

private func startTCPServer(_ server: AFMHTTPServer) async throws -> Int {
    let address = try await server.start()
    guard case .tcp(_, let port) = address else {
        throw BridgeClientTestError.unexpectedAddress
    }
    return port
}

private func makeBridgeClientTemporaryDirectory() throws -> String {
    let path = (NSTemporaryDirectory() as NSString)
        .appendingPathComponent("AFMBridgeClientTests-\(UUID().uuidString)")
    guard Darwin.mkdir(path, mode_t(0o700)) == 0 else {
        throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO)
    }
    return path
}

private struct BridgeClientTestClock: AFMServerClock {
    func unixTime() -> Int64 { 123 }
}

private struct BridgeClientTestGenerator: AFMChatCompletionGenerating {
    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        .init(
            content: "From bridge client",
            usage: .init(inputTokenCount: 2, measurement: .estimated, scope: .response)
        )
    }
}

private struct BridgeClientPausingGenerator: AFMChatCompletionGenerating {
    let probe: BridgeClientGenerationProbe?

    init(probe: BridgeClientGenerationProbe? = nil) {
        self.probe = probe
    }

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        await probe?.markStarted()
        try await ContinuousClock().sleep(for: .seconds(30))
        return .init(
            content: "Unexpected",
            usage: .init(inputTokenCount: 1, measurement: .estimated, scope: .response)
        )
    }
}

private actor BridgeClientGenerationProbe {
    private var started = false

    func markStarted() {
        started = true
    }

    func waitUntilStarted() async {
        while !started {
            await Task.yield()
        }
    }
}

private enum BridgeClientTestError: Error {
    case unexpectedAddress
}

private struct BridgeClientRedirectServer: Sendable {
    let port: Int
    let requests: Task<[String], Error>

    static func start() throws -> Self {
        let (listener, port) = try makeListener()
        let requests = Task.detached { () throws -> [String] in
            defer { Darwin.close(listener) }
            var received = [try acceptRequest(from: listener)]
            let redirect = "HTTP/1.1 302 Found\r\n"
                + "Location: http://127.0.0.1:\(port)/redirected\r\n"
                + "Content-Length: 0\r\nConnection: close\r\n\r\n"
            try respond(redirect, to: received[0].descriptor)
            Darwin.close(received[0].descriptor)

            var pollDescriptor = pollfd(fd: listener, events: Int16(POLLIN), revents: 0)
            let pollResult = Darwin.poll(&pollDescriptor, 1, 500)
            guard pollResult >= 0 else {
                throw BridgeClientSocketError(operation: "poll redirect listener", code: errno)
            }
            if pollResult > 0 {
                let request = try acceptRequest(from: listener)
                received.append(request)
                try respond(
                    "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}",
                    to: request.descriptor
                )
                Darwin.close(request.descriptor)
            }
            return received.map(\.text)
        }
        return Self(port: port, requests: requests)
    }

    private static func makeListener() throws -> (descriptor: CInt, port: Int) {
        let listener = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard listener >= 0 else {
            throw BridgeClientSocketError(operation: "create redirect listener", code: errno)
        }
        var shouldCloseListener = true
        defer {
            if shouldCloseListener {
                Darwin.close(listener)
            }
        }

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr = in_addr(s_addr: inet_addr("127.0.0.1"))
        let bindResult = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.bind(listener, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bindResult == 0 else {
            throw BridgeClientSocketError(operation: "bind redirect listener", code: errno)
        }
        guard Darwin.listen(listener, 2) == 0 else {
            throw BridgeClientSocketError(operation: "listen for redirects", code: errno)
        }

        var addressLength = socklen_t(MemoryLayout<sockaddr_in>.size)
        let nameResult = withUnsafeMutablePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.getsockname(listener, $0, &addressLength)
            }
        }
        guard nameResult == 0 else {
            throw BridgeClientSocketError(operation: "read redirect listener address", code: errno)
        }
        let port = Int(UInt16(bigEndian: address.sin_port))
        shouldCloseListener = false
        return (listener, port)
    }

    private static func acceptRequest(from listener: CInt) throws -> (descriptor: CInt, text: String) {
        let descriptor = Darwin.accept(listener, nil, nil)
        guard descriptor >= 0 else {
            throw BridgeClientSocketError(operation: "accept redirect request", code: errno)
        }
        do {
            var data = Data()
            var buffer = [UInt8](repeating: 0, count: 2_048)
            let separator = Data("\r\n\r\n".utf8)
            while data.range(of: separator) == nil, data.count < 65_536 {
                let count = Darwin.read(descriptor, &buffer, buffer.count)
                guard count > 0 else {
                    throw BridgeClientSocketError(operation: "read redirect request", code: errno)
                }
                data.append(contentsOf: buffer.prefix(count))
            }
            guard let text = String(data: data, encoding: .utf8) else {
                throw BridgeClientSocketError(operation: "decode redirect request", code: EILSEQ)
            }
            return (descriptor, text)
        } catch {
            Darwin.close(descriptor)
            throw error
        }
    }

    private static func respond(_ response: String, to descriptor: CInt) throws {
        let data = Data(response.utf8)
        try data.withUnsafeBytes { bytes in
            var offset = 0
            while offset < bytes.count {
                let count = Darwin.write(
                    descriptor,
                    bytes.baseAddress?.advanced(by: offset),
                    bytes.count - offset
                )
                guard count > 0 else {
                    throw BridgeClientSocketError(operation: "write redirect response", code: errno)
                }
                offset += count
            }
        }
    }
}

private struct BridgeClientSocketError: Error {
    let operation: String
    let code: Int32
}
