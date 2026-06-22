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
    private var requestBody = Data()
    private var responseWasSent = false
    private var shouldCloseForPipelinedRequest = false
    private var isClosingResponse = false
    private var generationTask: Task<Void, Never>?

    init(router: AFMRequestRouter, limits: AFMServerLimits) {
        self.router = router
        self.limits = limits
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard !isClosingResponse else { return }
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
        cancelGeneration()
        guard !isClosingResponse else {
            context.close(promise: nil)
            return
        }
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

    func channelInactive(context: ChannelHandlerContext) {
        cancelGeneration()
        context.fireChannelInactive()
    }

    func handlerRemoved(context: ChannelHandlerContext) {
        cancelGeneration()
    }

    private func receiveHead(_ head: HTTPRequestHead, context: ChannelHandlerContext) {
        guard requestHead == nil, !responseWasSent else {
            if generationTask != nil {
                shouldCloseForPipelinedRequest = true
                return
            }
            cancelGeneration()
            context.close(promise: nil)
            return
        }

        requestHead = head
        receivedBodyBytes = 0
        requestBody.removeAll(keepingCapacity: true)

        if let contentLength = declaredContentLength(head), contentLength > UInt64(limits.maximumBodyBytes) {
            responseWasSent = true
            sendPayloadTooLarge(version: head.version, context: context)
            return
        }

        if declaresBody(head) || router.requiresJSONBody(head), !hasJSONContentType(head) {
            responseWasSent = true
            sendUnsupportedMediaType(version: head.version, context: context)
        }
    }

    private func receiveBody(_ buffer: ByteBuffer, context: ChannelHandlerContext) {
        guard !shouldCloseForPipelinedRequest else { return }
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
        if let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes) {
            requestBody.append(contentsOf: bytes)
        }
    }

    private func receiveEnd(context: ChannelHandlerContext) {
        guard !shouldCloseForPipelinedRequest else { return }
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

        switch router.route(for: head) {
        case .immediate(let response):
            let shouldClose = !head.isKeepAlive
            resetRequestState()
            send(response, version: head.version, close: shouldClose, context: context)
        case .chatCompletion(let origin):
            startChatCompletion(head: head, body: requestBody, origin: origin, context: context)
        }
    }

    private func startChatCompletion(
        head: HTTPRequestHead,
        body: Data,
        origin: String?,
        context: ChannelHandlerContext
    ) {
        let router = router
        responseWasSent = true
        let writer = AFMAsyncHTTPResponseWriter(
            channel: context.channel,
            version: head.version,
            closeAfterResponse: !head.isKeepAlive
        )
        let contextReference = AFMChannelContextReference(context)
        let eventLoop = context.eventLoop
        generationTask = Task { [weak self] in
            do {
                try await router.writeChatCompletionResponse(body: body, origin: origin) { emission in
                    try await writer.write(emission)
                }
            } catch is CancellationError {
                return
            } catch {
                if !writer.hasStarted {
                    try? await writer.write(
                        .fixed(
                            .apiError(
                                status: .internalServerError,
                                message: "The chat completion request failed.",
                                code: "internal_error",
                                type: "server_error"
                            )
                        )
                    )
                } else {
                    await writer.abort()
                }
            }
            guard !Task.isCancelled else { return }
            eventLoop.execute { [weak self] in
                self?.completeChatCompletion(context: contextReference.context)
            }
        }
    }

    private func completeChatCompletion(context: ChannelHandlerContext) {
        generationTask = nil
        guard requestHead != nil, context.channel.isActive else { return }
        let shouldClose = shouldCloseForPipelinedRequest
        resetRequestState()
        if shouldClose {
            isClosingResponse = true
            context.close(promise: nil)
        }
    }
}

private final class AFMChannelContextReference: @unchecked Sendable {
    let context: ChannelHandlerContext

    init(_ context: ChannelHandlerContext) {
        self.context = context
    }
}

private extension AFMHTTPHandler {
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
        if close {
            isClosingResponse = true
        }
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
        requestBody.removeAll(keepingCapacity: true)
        responseWasSent = false
        shouldCloseForPipelinedRequest = false
    }

    private func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
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
