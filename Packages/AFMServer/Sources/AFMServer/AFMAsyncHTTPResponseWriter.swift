import Foundation
import NIOCore
import NIOHTTP1

final class AFMAsyncHTTPResponseWriter: @unchecked Sendable {
    enum WriterError: Error {
        case invalidEmissionSequence
        case inactiveChannel
    }

    private let channel: any Channel
    private let version: HTTPVersion
    private let closeAfterResponse: Bool
    private var responseStarted = false
    private var isStreaming = false
    private var responseEnded = false

    var hasStarted: Bool {
        responseStarted
    }

    init(channel: any Channel, version: HTTPVersion, closeAfterResponse: Bool) {
        self.channel = channel
        self.version = version
        self.closeAfterResponse = closeAfterResponse || version != .http1_1
    }

    func write(_ emission: AFMHTTPEmission) async throws {
        guard channel.isActive else { throw WriterError.inactiveChannel }
        switch emission {
        case .fixed(let response):
            guard !responseStarted, !responseEnded else { throw WriterError.invalidEmissionSequence }
            responseStarted = true
            try await writeFixed(response)
            responseEnded = true
        case .streamHead(let status, let headers):
            guard !responseStarted, !responseEnded else { throw WriterError.invalidEmissionSequence }
            responseStarted = true
            isStreaming = true
            try await writeStreamHead(status: status, headers: headers)
        case .streamBody(let data):
            guard isStreaming, !responseEnded else { throw WriterError.invalidEmissionSequence }
            try await writeBody(data)
        case .streamEnd:
            guard isStreaming, !responseEnded else { throw WriterError.invalidEmissionSequence }
            try await writeEnd()
            responseEnded = true
        }
    }

    func abort() async {
        if channel.isActive {
            try? await channel.close().get()
        }
    }

    private func writeFixed(_ response: AFMHTTPResponse) async throws {
        var headers = response.headers
        headers.replaceOrAdd(name: "content-type", value: "application/json")
        headers.replaceOrAdd(name: "content-length", value: String(response.body.count))
        addSecurityHeaders(to: &headers, streaming: false)
        try await writeHead(status: response.status, headers: headers)
        if !response.body.isEmpty {
            try await writeBody(response.body)
        }
        try await writeEnd()
    }

    private func writeStreamHead(status: HTTPResponseStatus, headers originalHeaders: HTTPHeaders) async throws {
        var headers = originalHeaders
        headers.replaceOrAdd(name: "content-type", value: "text/event-stream")
        headers.remove(name: "content-length")
        if version == .http1_1 {
            headers.replaceOrAdd(name: "transfer-encoding", value: "chunked")
        }
        addSecurityHeaders(to: &headers, streaming: true)
        try await writeHead(status: status, headers: headers)
    }

    private func addSecurityHeaders(to headers: inout HTTPHeaders, streaming: Bool) {
        headers.replaceOrAdd(name: "cache-control", value: streaming ? "no-cache" : "no-store")
        headers.replaceOrAdd(name: "x-content-type-options", value: "nosniff")
        if closeAfterResponse {
            headers.replaceOrAdd(name: "connection", value: "close")
        } else if streaming {
            headers.replaceOrAdd(name: "connection", value: "keep-alive")
        }
    }

    private func writeHead(status: HTTPResponseStatus, headers: HTTPHeaders) async throws {
        let head = HTTPResponseHead(version: version, status: status, headers: headers)
        try await channel.writeAndFlush(HTTPServerResponsePart.head(head)).get()
    }

    private func writeBody(_ data: Data) async throws {
        guard !data.isEmpty else { return }
        var buffer = channel.allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        try await channel.writeAndFlush(HTTPServerResponsePart.body(.byteBuffer(buffer))).get()
    }

    private func writeEnd() async throws {
        try await channel.writeAndFlush(HTTPServerResponsePart.end(nil)).get()
        if closeAfterResponse, channel.isActive {
            try await channel.close().get()
        }
    }
}
