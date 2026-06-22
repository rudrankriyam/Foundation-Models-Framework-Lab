import Foundation
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

    private func validateModel(_ identifier: String) -> AFMHTTPResponse? {
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

    private func generateWithTimeout(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
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

    private func completionResponse(
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
                        message: .init(content: result.content, refusal: result.refusal),
                        finishReason: result.finishReason
                    )
                ],
                usage: .init(result.usage)
            )
        )
    }

    private func validationErrorResponse(_ error: AFMChatRequestValidationError) -> AFMHTTPResponse {
        .apiError(
            status: .badRequest,
            message: error.message,
            code: error.code,
            parameter: error.parameter
        )
    }

    private func generationErrorResponse(_ error: Error) -> AFMHTTPResponse {
        switch error {
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

    private func generationFailure(
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
