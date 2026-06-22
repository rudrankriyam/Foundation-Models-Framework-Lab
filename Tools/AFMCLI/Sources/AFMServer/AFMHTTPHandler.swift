import Foundation
import NIOCore
import NIOHTTP1

final class AFMHTTPHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let router: AFMRequestRouter
    private let limits: AFMServerLimits
    private var requestHead: HTTPRequestHead?
    private var receivedBodyBytes = 0
    private var responseWasSent = false

    init(router: AFMRequestRouter, limits: AFMServerLimits) {
        self.router = router
        self.limits = limits
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head):
            receiveHead(head, context: context)
        case .body(let buffer):
            receiveBody(buffer, context: context)
        case .end:
            receiveEnd(context: context)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        guard !responseWasSent else {
            context.close(promise: nil)
            return
        }

        let response: AFMHTTPResponse
        if case HTTPParserError.headerOverflow = error {
            response = .apiError(
                status: .custom(code: 431, reasonPhrase: "Request Header Fields Too Large"),
                message: "Request headers exceed the server limit.",
                code: "headers_too_large"
            )
        } else if error is HTTPParserError {
            response = .apiError(
                status: .badRequest,
                message: "The HTTP request could not be parsed.",
                code: "invalid_http_request"
            )
        } else {
            context.close(promise: nil)
            return
        }

        responseWasSent = true
        send(response, version: requestHead?.version ?? .http1_1, close: true, context: context)
    }

    private func receiveHead(_ head: HTTPRequestHead, context: ChannelHandlerContext) {
        guard requestHead == nil, !responseWasSent else {
            responseWasSent = true
            send(
                .apiError(
                    status: .badRequest,
                    message: "Only one request may be active on a connection.",
                    code: "invalid_http_request"
                ),
                version: head.version,
                close: true,
                context: context
            )
            return
        }

        requestHead = head
        receivedBodyBytes = 0

        if let contentLength = declaredContentLength(head), contentLength > UInt64(limits.maximumBodyBytes) {
            responseWasSent = true
            sendPayloadTooLarge(version: head.version, context: context)
            return
        }

        if declaresBody(head), !hasJSONContentType(head) {
            responseWasSent = true
            sendUnsupportedMediaType(version: head.version, context: context)
        }
    }

    private func receiveBody(_ buffer: ByteBuffer, context: ChannelHandlerContext) {
        guard let head = requestHead, !responseWasSent else { return }

        if receivedBodyBytes == 0, !declaresBody(head), !hasJSONContentType(head) {
            responseWasSent = true
            sendUnsupportedMediaType(version: head.version, context: context)
            return
        }

        let (newCount, overflowed) = receivedBodyBytes.addingReportingOverflow(buffer.readableBytes)
        guard !overflowed, newCount <= limits.maximumBodyBytes else {
            responseWasSent = true
            sendPayloadTooLarge(version: head.version, context: context)
            return
        }
        receivedBodyBytes = newCount
    }

    private func receiveEnd(context: ChannelHandlerContext) {
        guard let head = requestHead else {
            if !responseWasSent {
                responseWasSent = true
                send(
                    .apiError(
                        status: .badRequest,
                        message: "The HTTP request is missing its request line and headers.",
                        code: "invalid_http_request"
                    ),
                    version: .http1_1,
                    close: true,
                    context: context
                )
            }
            return
        }
        guard !responseWasSent else { return }

        let response = router.response(for: head)
        let shouldClose = !head.isKeepAlive
        send(response, version: head.version, close: shouldClose, context: context)
        resetRequestState()
    }

    private func sendPayloadTooLarge(version: HTTPVersion, context: ChannelHandlerContext) {
        send(
            .apiError(
                status: .payloadTooLarge,
                message: "Request bodies may not exceed \(limits.maximumBodyBytes) bytes.",
                code: "request_too_large"
            ),
            version: version,
            close: true,
            context: context
        )
    }

    private func sendUnsupportedMediaType(version: HTTPVersion, context: ChannelHandlerContext) {
        send(
            .apiError(
                status: .unsupportedMediaType,
                message: "Request bodies must use Content-Type: application/json.",
                code: "unsupported_media_type"
            ),
            version: version,
            close: true,
            context: context
        )
    }

    private func send(
        _ response: AFMHTTPResponse,
        version: HTTPVersion,
        close: Bool,
        context: ChannelHandlerContext
    ) {
        var headers = response.headers
        headers.replaceOrAdd(name: "content-type", value: "application/json")
        headers.replaceOrAdd(name: "content-length", value: String(response.body.count))
        headers.replaceOrAdd(name: "cache-control", value: "no-store")
        headers.replaceOrAdd(name: "x-content-type-options", value: "nosniff")
        if close {
            headers.replaceOrAdd(name: "connection", value: "close")
        }

        let head = HTTPResponseHead(version: version, status: response.status, headers: headers)
        context.write(wrapOutboundOut(.head(head)), promise: nil)
        if !response.body.isEmpty {
            var buffer = context.channel.allocator.buffer(capacity: response.body.count)
            buffer.writeBytes(response.body)
            context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        }

        let completion = context.writeAndFlush(wrapOutboundOut(.end(nil)))
        if close {
            let channel = context.channel
            completion.whenComplete { _ in
                channel.close(promise: nil)
            }
        }
    }

    private func resetRequestState() {
        requestHead = nil
        receivedBodyBytes = 0
        responseWasSent = false
    }

    private func declaredContentLength(_ head: HTTPRequestHead) -> UInt64? {
        head.headers.first(name: "content-length").flatMap(UInt64.init)
    }

    private func declaresBody(_ head: HTTPRequestHead) -> Bool {
        if let contentLength = declaredContentLength(head), contentLength > 0 {
            return true
        }
        return head.headers.contains(name: "transfer-encoding")
    }

    private func hasJSONContentType(_ head: HTTPRequestHead) -> Bool {
        guard let contentType = head.headers.first(name: "content-type") else { return false }
        let mediaType = contentType.split(separator: ";", maxSplits: 1).first?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return mediaType == "application/json"
    }
}
