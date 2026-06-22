import Foundation
import FoundationModelsKit
import NIOHTTP1

actor AFMGenerationGate {
    private var availablePermits: Int

    init(limit: Int) {
        availablePermits = limit
    }

    func tryAcquire() -> Bool {
        guard availablePermits > 0 else { return false }
        availablePermits -= 1
        return true
    }

    func release() {
        availablePermits += 1
    }
}

private actor AFMToolStreamContentBuffer {
    private var deltas: [String] = []

    func append(_ delta: String) {
        deltas.append(delta)
    }

    func snapshot() -> [String] {
        deltas
    }
}

struct AFMChatCompletionService: Sendable {
    private let catalog: any AFMModelCatalog
    private let generator: any AFMChatCompletionGenerating
    private let clock: any AFMServerClock
    private let gate: AFMGenerationGate
    private let timeoutSeconds: Double

    init(
        catalog: any AFMModelCatalog,
        generator: any AFMChatCompletionGenerating,
        clock: any AFMServerClock,
        policy: AFMServerGenerationPolicy
    ) {
        self.catalog = catalog
        self.generator = generator
        self.clock = clock
        gate = AFMGenerationGate(limit: policy.maximumConcurrentGenerations)
        timeoutSeconds = policy.timeoutSeconds
    }

    func response(for body: Data) async throws -> AFMHTTPResponse {
        let request: AFMChatGenerationRequest
        do {
            request = try AFMChatGenerationRequest.decode(body)
        } catch let error as AFMChatRequestValidationError {
            return validationErrorResponse(error)
        }

        if let modelError = validateModel(request.model) {
            return modelError
        }
        guard await gate.tryAcquire() else {
            return .apiError(
                status: .tooManyRequests,
                message: "The local model is already handling the configured number of requests.",
                code: "server_busy",
                type: "rate_limit_error"
            )
        }

        do {
            let result = try await generateWithTimeout(request)
            await gate.release()
            return completionResponse(result, request: request)
        } catch is CancellationError {
            await gate.release()
            throw CancellationError()
        } catch {
            await gate.release()
            return generationErrorResponse(error)
        }
    }

    func writeResponse(
        for body: Data,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        let request: AFMChatGenerationRequest
        do {
            request = try AFMChatGenerationRequest.decode(body)
        } catch let error as AFMChatRequestValidationError {
            try await emission(.fixed(validationErrorResponse(error)))
            return
        }

        guard request.stream else {
            try await emission(.fixed(try await response(for: body)))
            return
        }
        if let modelError = validateModel(request.model) {
            try await emission(.fixed(modelError))
            return
        }
        guard await gate.tryAcquire() else {
            try await emission(.fixed(serverBusyResponse()))
            return
        }

        try await writeStreamingResponse(request, emitting: emission)
    }
}

private extension AFMChatCompletionService {
    func writeStreamingResponse(
        _ request: AFMChatGenerationRequest,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        var sentStreamHead = false
        do {
            let identifier = "chatcmpl-\(UUID().uuidString)"
            let created = clock.unixTime()
            try await emission(.streamHead(status: .ok, headers: .init()))
            sentStreamHead = true
            try await writeChunk(
                identifier: identifier,
                created: created,
                role: "assistant",
                request: request,
                emitting: emission
            )

            let result = try await streamAndWriteContent(
                request,
                identifier: identifier,
                created: created,
                emitting: emission
            )
            try await writeTerminalChunks(
                result,
                identifier: identifier,
                created: created,
                request: request,
                emitting: emission
            )
            try await emission(.streamBody(AFMServerSentEventEncoder().done))
            try await emission(.streamEnd)
            await gate.release()
        } catch is CancellationError {
            await gate.release()
            throw CancellationError()
        } catch let error as AFMAsyncHTTPResponseWriter.WriterError {
            await gate.release()
            throw error
        } catch {
            await gate.release()
            if sentStreamHead {
                let response = generationErrorResponse(error)
                try await emission(.streamBody(AFMServerSentEventEncoder().event(json: response.body)))
                try await emission(.streamEnd)
            } else {
                try await emission(.fixed(generationErrorResponse(error)))
            }
        }
    }

    func streamAndWriteContent(
        _ request: AFMChatGenerationRequest,
        identifier: String,
        created: Int64,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        let buffersToolContent = !request.tools.isEmpty && request.toolChoice != .none
        let contentBuffer = AFMToolStreamContentBuffer()
        let result = try await streamWithTimeout(request) { event in
            switch event {
            case .contentDelta(let content):
                if buffersToolContent {
                    await contentBuffer.append(content)
                } else {
                    try await writeChunk(
                        identifier: identifier,
                        created: created,
                        content: content,
                        request: request,
                        emitting: emission
                    )
                }
            }
        }
        if result.toolCalls.isEmpty {
            for content in await contentBuffer.snapshot() {
                try await writeChunk(
                    identifier: identifier,
                    created: created,
                    content: content,
                    request: request,
                    emitting: emission
                )
            }
        }
        return result
    }

    func validateModel(_ identifier: String) -> AFMHTTPResponse? {
        guard let model = catalog.models().first(where: { $0.id == identifier }) else {
            return .apiError(
                status: .notFound,
                message: "Model '\(identifier)' does not exist.",
                code: "model_not_found",
                parameter: "model"
            )
        }
        guard model.isAvailable else {
            return .apiError(
                status: .serviceUnavailable,
                message: "Model '\(identifier)' is not currently available on this Mac.",
                code: "model_unavailable",
                type: "server_error",
                parameter: "model"
            )
        }
        return nil
    }

    func serverBusyResponse() -> AFMHTTPResponse {
        .apiError(
            status: .tooManyRequests,
            message: "The local model is already handling the configured number of requests.",
            code: "server_busy",
            type: "rate_limit_error"
        )
    }

    func generateWithTimeout(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        try await withThrowingTaskGroup(of: AFMChatGenerationResult.self) { group in
            group.addTask {
                try await generator.generate(request)
            }
            group.addTask {
                try await ContinuousClock().sleep(for: .seconds(timeoutSeconds))
                throw AFMChatServiceError.timedOut
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw AFMChatServiceError.missingResult
            }
            return result
        }
    }

    func streamWithTimeout(
        _ request: AFMChatGenerationRequest,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        try await withThrowingTaskGroup(of: AFMChatGenerationResult.self) { group in
            group.addTask {
                try await generator.stream(request, emitting: event)
            }
            group.addTask {
                try await ContinuousClock().sleep(for: .seconds(timeoutSeconds))
                throw AFMChatServiceError.timedOut
            }
            defer { group.cancelAll() }
            guard let result = try await group.next() else {
                throw AFMChatServiceError.missingResult
            }
            return result
        }
    }

    func completionResponse(
        _ result: AFMChatGenerationResult,
        request: AFMChatGenerationRequest
    ) -> AFMHTTPResponse {
        .json(
            body: AFMChatCompletionPayload(
                id: "chatcmpl-\(UUID().uuidString)",
                created: clock.unixTime(),
                model: request.model,
                choices: [
                    .init(
                        index: 0,
                        message: .init(
                            content: result.content,
                            refusal: result.refusal,
                            toolCalls: result.toolCalls
                        ),
                        finishReason: result.finishReason
                    )
                ],
                usage: .init(result.usage)
            )
        )
    }

    func writeChunk(
        identifier: String,
        created: Int64,
        role: String? = nil,
        content: String? = nil,
        refusal: String? = nil,
        toolCalls: [AFMChatToolCall]? = nil,
        finishReason: AFMChatFinishReason? = nil,
        request: AFMChatGenerationRequest,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        let chunk = AFMChatCompletionChunk(
            id: identifier,
            created: created,
            model: request.model,
            choices: [
                .init(
                    index: 0,
                    delta: .init(
                        role: role,
                        content: content,
                        refusal: refusal,
                        toolCalls: toolCalls
                    ),
                    finishReason: finishReason
                )
            ],
            usage: nil
        )
        try await emission(.streamBody(try AFMServerSentEventEncoder().event(chunk)))
    }

    func writeRefusalChunk(
        _ refusal: String?,
        identifier: String,
        created: Int64,
        request: AFMChatGenerationRequest,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        guard let refusal else { return }
        try await writeChunk(
            identifier: identifier,
            created: created,
            refusal: refusal,
            request: request,
            emitting: emission
        )
    }

    func writeTerminalChunks(
        _ result: AFMChatGenerationResult,
        identifier: String,
        created: Int64,
        request: AFMChatGenerationRequest,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        if !result.toolCalls.isEmpty {
            try await writeChunk(
                identifier: identifier,
                created: created,
                toolCalls: result.toolCalls,
                request: request,
                emitting: emission
            )
        }
        try await writeRefusalChunk(
            result.refusal,
            identifier: identifier,
            created: created,
            request: request,
            emitting: emission
        )
        try await writeChunk(
            identifier: identifier,
            created: created,
            finishReason: result.finishReason,
            request: request,
            emitting: emission
        )
        if request.streamOptions?.includeUsage == true {
            try await writeUsageChunk(
                result.usage,
                identifier: identifier,
                created: created,
                request: request,
                emitting: emission
            )
        }
    }

    func writeUsageChunk(
        _ usage: ModelTokenUsage,
        identifier: String,
        created: Int64,
        request: AFMChatGenerationRequest,
        emitting emission: @escaping @Sendable (AFMHTTPEmission) async throws -> Void
    ) async throws {
        let chunk = AFMChatCompletionChunk(
            id: identifier,
            created: created,
            model: request.model,
            choices: [],
            usage: .init(usage)
        )
        try await emission(.streamBody(try AFMServerSentEventEncoder().event(chunk)))
    }

    func validationErrorResponse(_ error: AFMChatRequestValidationError) -> AFMHTTPResponse {
        .apiError(
            status: .badRequest,
            message: error.message,
            code: error.code,
            parameter: error.parameter
        )
    }

    func generationErrorResponse(_ error: Error) -> AFMHTTPResponse {
        if let toolErrorResponse = toolGenerationErrorResponse(error) {
            return toolErrorResponse
        }
        return switch error {
        case AFMChatServiceError.timedOut:
            .apiError(
                status: .gatewayTimeout,
                message: "The local model did not finish before the configured timeout.",
                code: "model_timeout",
                type: "server_error"
            )
        case AFMChatGenerationError.contextLengthExceeded:
            generationFailure(
                .badRequest,
                "The conversation exceeds the model context window.",
                "context_length_exceeded",
                type: "invalid_request_error"
            )
        case AFMChatGenerationError.modelUnavailable:
            generationFailure(.serviceUnavailable, "The local model became unavailable.", "model_unavailable")
        case AFMChatGenerationError.rateLimited:
            generationFailure(
                .tooManyRequests,
                "The local model is temporarily rate limited.",
                "rate_limited",
                type: "rate_limit_error"
            )
        case AFMChatGenerationError.safetyViolation:
            generationFailure(
                .badRequest,
                "The request was blocked by the model safety guardrails.",
                "safety_violation",
                type: "invalid_request_error"
            )
        case AFMChatGenerationError.unsupportedInput:
            generationFailure(
                .badRequest,
                "The conversation contains content the model cannot process.",
                "unsupported_input",
                type: "invalid_request_error"
            )
        case AFMChatGenerationError.concurrentRequest:
            generationFailure(
                .tooManyRequests,
                "The local model rejected a concurrent request.",
                "server_busy",
                type: "rate_limit_error"
            )
        case AFMChatGenerationError.timedOut:
            generationFailure(.gatewayTimeout, "The local model request timed out.", "model_timeout")
        default:
            generationFailure(.internalServerError, "The local model request failed.", "model_error")
        }
    }

    func toolGenerationErrorResponse(_ error: Error) -> AFMHTTPResponse? {
        switch error {
        case AFMChatGenerationError.unsupportedToolChoice:
            .apiError(
                status: .badRequest,
                message: "This OS cannot guarantee the requested tool_choice semantics.",
                code: "unsupported_tool_choice",
                type: "invalid_request_error",
                parameter: "tool_choice"
            )
        case AFMChatGenerationError.requiredToolNotCalled:
            .apiError(
                status: .internalServerError,
                message: "The model did not satisfy the required tool choice.",
                code: "required_tool_not_called",
                type: "server_error",
                parameter: "tool_choice"
            )
        case AFMChatGenerationError.toolCallLimitExceeded:
            .apiError(
                status: .badRequest,
                message: "The model exceeded the local tool-call size or count limit.",
                code: "tool_call_limit_exceeded",
                type: "invalid_request_error",
                parameter: "tools"
            )
        default:
            nil
        }
    }

    func generationFailure(
        _ status: HTTPResponseStatus,
        _ message: String,
        _ code: String,
        type: String = "server_error"
    ) -> AFMHTTPResponse {
        .apiError(status: status, message: message, code: code, type: type)
    }
}

private enum AFMChatServiceError: Error {
    case timedOut
    case missingResult
}
