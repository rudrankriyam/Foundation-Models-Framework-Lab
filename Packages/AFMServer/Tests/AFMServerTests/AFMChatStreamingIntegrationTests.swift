import Darwin
import Foundation
import FoundationModelsKit
import Testing
@testable import AFMServer

@Suite("Streaming chat transport")
struct AFMChatStreamingIntegrationTests {
    @Test("TCP streams the first SSE delta before generation completes")
    func tcpStreamingFlushesIncrementally() async throws {
        let probe = StagedProbe()
        let server = try Self.server(generator: StagedGenerator(probe: probe))

        do {
            let address = try await server.start()
            guard case .tcp(_, let port) = address else {
                Issue.record("Expected a TCP address")
                try await server.stop()
                return
            }
            let descriptor = try Self.connect(port: port)
            defer { Darwin.close(descriptor) }
            try Self.write(Self.request(port: port), to: descriptor)

            await probe.waitUntilFirstDeltaWasWritten()
            let prefix = try Self.readUntil(#""content":"first""#, from: descriptor)
            #expect(!(await probe.didComplete()))
            #expect(prefix.lowercased().contains("content-type: text/event-stream"))
            #expect(prefix.lowercased().contains("transfer-encoding: chunked"))
            let header = prefix.split(separator: "\r\n\r\n", maxSplits: 1).first.map(String.init) ?? ""
            #expect(!header.lowercased().contains("content-length:"))
            #expect(prefix.contains(#""role":"assistant""#))

            await probe.release()
            let response = prefix + (try Self.readToEnd(from: descriptor))
            #expect(response.hasPrefix("HTTP/1.1 200 OK"))
            #expect(response.contains(#""content":"second""#))
            #expect(response.contains(#""finish_reason":"stop""#))
            #expect(response.contains(#""choices":[],"created":123"#))
            #expect(response.contains(#""prompt_tokens":2"#))
            #expect(response.contains("data: [DONE]\n\n"))
            #expect(try Self.offset(of: #""content":"first""#, in: response) < Self.offset(of: #""content":"second""#, in: response))
            #expect(try Self.offset(of: #""finish_reason":"stop""#, in: response) < Self.offset(of: "data: [DONE]", in: response))
            #expect(await probe.didComplete())
            try await server.stop()
        } catch {
            await probe.release()
            try? await server.stop()
            throw error
        }
    }

    @Test("A TCP disconnect cancels streaming generation")
    func tcpStreamingDisconnectCancellation() async throws {
        let probe = CancellationProbe()
        let server = try Self.server(generator: PausingGenerator(probe: probe))

        do {
            let address = try await server.start()
            guard case .tcp(_, let port) = address else {
                Issue.record("Expected a TCP address")
                try await server.stop()
                return
            }
            let descriptor = try Self.connect(port: port)
            try Self.write(Self.request(port: port, close: false), to: descriptor)
            await probe.waitUntilStarted()

            var reset = linger(l_onoff: 1, l_linger: 0)
            #expect(
                setsockopt(
                    descriptor,
                    SOL_SOCKET,
                    SO_LINGER,
                    &reset,
                    socklen_t(MemoryLayout<linger>.size)
                ) == 0
            )
            #expect(Darwin.close(descriptor) == 0)
            await probe.waitUntilCancelled()
            try await server.stop()
        } catch {
            try? await server.stop()
            throw error
        }
    }
}

private extension AFMChatStreamingIntegrationTests {
    struct StagedGenerator: AFMChatCompletionGenerating {
        let probe: StagedProbe

        func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
            Self.result
        }

        func stream(
            _ request: AFMChatGenerationRequest,
            emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
        ) async throws -> AFMChatGenerationResult {
            try await event(.contentDelta("first"))
            await probe.markFirstDeltaWasWritten()
            await probe.waitUntilReleased()
            try await event(.contentDelta("second"))
            await probe.markCompleted()
            return Self.result
        }

        static let result = AFMChatGenerationResult(
            content: "firstsecond",
            usage: .init(
                input: .init(totalTokenCount: 2),
                output: .init(totalTokenCount: 2),
                measurement: .estimated,
                scope: .response
            )
        )
    }

    struct PausingGenerator: AFMChatCompletionGenerating {
        let probe: CancellationProbe

        func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
            throw CancellationError()
        }

        func stream(
            _ request: AFMChatGenerationRequest,
            emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
        ) async throws -> AFMChatGenerationResult {
            try await withTaskCancellationHandler {
                try await event(.contentDelta("first"))
                await probe.markStarted()
                try await ContinuousClock().sleep(for: .seconds(30))
                return StagedGenerator.result
            } onCancel: {
                Task { await probe.markCancelled() }
            }
        }
    }

    actor StagedProbe {
        private var firstDeltaWasWritten = false
        private var completed = false
        private var released = false
        private var releaseContinuation: CheckedContinuation<Void, Never>?

        func markFirstDeltaWasWritten() { firstDeltaWasWritten = true }
        func markCompleted() { completed = true }
        func didComplete() -> Bool { completed }

        func waitUntilFirstDeltaWasWritten() async {
            while !firstDeltaWasWritten {
                await Task.yield()
            }
        }

        func waitUntilReleased() async {
            guard !released else { return }
            await withCheckedContinuation { releaseContinuation = $0 }
        }

        func release() {
            released = true
            releaseContinuation?.resume()
            releaseContinuation = nil
        }
    }

    actor CancellationProbe {
        private var started = false
        private var cancelled = false

        func markStarted() { started = true }
        func markCancelled() { cancelled = true }

        func waitUntilStarted() async {
            while !started {
                await Task.yield()
            }
        }

        func waitUntilCancelled() async {
            while !cancelled {
                await Task.yield()
            }
        }
    }

    struct TestClock: AFMServerClock {
        func unixTime() -> Int64 { 123 }
    }

    struct SocketError: Error {
        let operation: String
        let code: Int32
    }

    static func server(generator: any AFMChatCompletionGenerating) throws -> AFMHTTPServer {
        try AFMHTTPServer(
            configuration: .init(endpoint: .tcp(host: "127.0.0.1", port: 0)),
            catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
            clock: TestClock(),
            generator: generator
        )
    }

    static func request(port: Int, close: Bool = true) -> String {
        let body = #"""
        {"model":"system","messages":[{"role":"user","content":"Hi"}],"stream":true,
        "stream_options":{"include_usage":true},"tools":[],"tool_choice":"auto"}
        """#
        var request = "POST /v1/chat/completions HTTP/1.1\r\n"
        request += "Host: 127.0.0.1:\(port)\r\n"
        request += "Content-Type: application/json\r\n"
        request += "Content-Length: \(body.utf8.count)\r\n"
        if close {
            request += "Connection: close\r\n"
        }
        return request + "\r\n" + body
    }

    static func connect(port: Int) throws -> CInt {
        let descriptor = Darwin.socket(AF_INET, SOCK_STREAM, 0)
        guard descriptor >= 0 else { throw SocketError(operation: "socket", code: errno) }
        var shouldClose = true
        defer {
            if shouldClose {
                Darwin.close(descriptor)
            }
        }

        var timeout = timeval(tv_sec: 2, tv_usec: 0)
        guard setsockopt(
            descriptor,
            SOL_SOCKET,
            SO_RCVTIMEO,
            &timeout,
            socklen_t(MemoryLayout<timeval>.size)
        ) == 0 else {
            throw SocketError(operation: "setsockopt", code: errno)
        }

        var address = sockaddr_in()
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = in_port_t(port).bigEndian
        guard "127.0.0.1".withCString({ inet_pton(AF_INET, $0, &address.sin_addr) }) == 1 else {
            throw SocketError(operation: "inet_pton", code: errno)
        }
        let result = withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                Darwin.connect(descriptor, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard result == 0 else { throw SocketError(operation: "connect", code: errno) }
        shouldClose = false
        return descriptor
    }

    static func write(_ request: String, to descriptor: CInt) throws {
        try Array(request.utf8).withUnsafeBytes { buffer in
            var sent = 0
            while sent < buffer.count {
                let count = Darwin.write(
                    descriptor,
                    buffer.baseAddress?.advanced(by: sent),
                    buffer.count - sent
                )
                guard count > 0 else { throw SocketError(operation: "write", code: errno) }
                sent += count
            }
        }
    }

    static func readUntil(_ needle: String, from descriptor: CInt) throws -> String {
        var response = ""
        while !response.contains(needle) {
            let chunk = try readChunk(from: descriptor)
            guard !chunk.isEmpty else { break }
            response += chunk
        }
        return response
    }

    static func readToEnd(from descriptor: CInt) throws -> String {
        var response = ""
        while true {
            let chunk = try readChunk(from: descriptor)
            guard !chunk.isEmpty else { return response }
            response += chunk
        }
    }

    static func readChunk(from descriptor: CInt) throws -> String {
        var bytes = [UInt8](repeating: 0, count: 4_096)
        let count = Darwin.read(descriptor, &bytes, bytes.count)
        if count > 0 {
            return String(bytes: bytes.prefix(count), encoding: .utf8) ?? ""
        }
        if count == 0 {
            return ""
        }
        throw SocketError(operation: "read", code: errno)
    }

    static func offset(of needle: String, in value: String) throws -> Int {
        let range = try #require(value.range(of: needle))
        return value.distance(from: value.startIndex, to: range.lowerBound)
    }
}
