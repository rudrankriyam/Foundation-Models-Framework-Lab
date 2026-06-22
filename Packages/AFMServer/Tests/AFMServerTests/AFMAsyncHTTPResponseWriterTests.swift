import Foundation
import NIOCore
import NIOEmbedded
import NIOHTTP1
import Testing
@testable import AFMServer

@Suite("Async HTTP response writer")
struct AFMAsyncHTTPResponseWriterTests {
    @Test("A partial fixed response remains marked as started")
    func partialFixedResponseTracksStartedState() async throws {
        let channel = EmbeddedChannel(handler: FailingBodyHandler())
        try await channel.connect(
            to: SocketAddress(unixDomainSocketPath: "/afm-writer-test")
        ).get()
        let writer = AFMAsyncHTTPResponseWriter(
            channel: channel,
            version: .http1_1,
            closeAfterResponse: false
        )

        do {
            try await writer.write(
                .fixed(.init(status: .ok, body: Data("body".utf8)))
            )
            Issue.record("Expected the response body write to fail")
        } catch let error as WriteFailure {
            #expect(error == .body)
        } catch {
            Issue.record("Unexpected writer error: \(error)")
        }

        #expect(writer.hasStarted)
        let outbound = try #require(
            try channel.readOutbound(as: HTTPServerResponsePart.self)
        )
        guard case .head(let head) = outbound else {
            Issue.record("Expected the response head to be written before the body failed")
            return
        }
        #expect(head.status == .ok)
        #expect(try channel.readOutbound(as: HTTPServerResponsePart.self) == nil)
        _ = try? channel.finish()
    }
}

private extension AFMAsyncHTTPResponseWriterTests {
    enum WriteFailure: Error, Equatable {
        case body
    }

    final class FailingBodyHandler: ChannelOutboundHandler, @unchecked Sendable {
        typealias OutboundIn = HTTPServerResponsePart
        typealias OutboundOut = HTTPServerResponsePart

        func write(
            context: ChannelHandlerContext,
            data: NIOAny,
            promise: EventLoopPromise<Void>?
        ) {
            let part = unwrapOutboundIn(data)
            if case .body = part {
                promise?.fail(WriteFailure.body)
            } else {
                context.write(wrapOutboundOut(part), promise: promise)
            }
        }
    }
}
