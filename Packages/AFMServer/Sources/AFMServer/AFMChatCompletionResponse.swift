import Foundation
import FoundationModelsKit

public enum AFMChatFinishReason: String, Sendable, Equatable, Encodable {
    case stop
    case length
    case contentFilter = "content_filter"
    case toolCalls = "tool_calls"
}

public struct AFMChatGenerationResult: Sendable, Equatable {
    public let content: String?
    public let refusal: String?
    public let finishReason: AFMChatFinishReason
    public let usage: ModelTokenUsage
    public let toolCalls: [AFMChatToolCall]

    public init(
        content: String?,
        refusal: String? = nil,
        finishReason: AFMChatFinishReason = .stop,
        usage: ModelTokenUsage,
        toolCalls: [AFMChatToolCall] = []
    ) {
        self.content = content
        self.refusal = refusal
        self.finishReason = finishReason
        self.usage = usage
        self.toolCalls = toolCalls
    }
}

public protocol AFMChatCompletionGenerating: Sendable {
    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult

    func stream(
        _ request: AFMChatGenerationRequest,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult
}

public extension AFMChatCompletionGenerating {
    func stream(
        _ request: AFMChatGenerationRequest,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        let result = try await generate(request)
        if let content = result.content, !content.isEmpty {
            try await event(.contentDelta(content))
        }
        return result
    }
}

public enum AFMChatGenerationError: Error, Sendable, Equatable {
    case contextLengthExceeded
    case modelUnavailable
    case rateLimited
    case safetyViolation
    case unsupportedInput
    case concurrentRequest
    case timedOut
    case unsupportedToolChoice
    case requiredToolNotCalled
    case toolCallLimitExceeded
}

struct AFMChatCompletionPayload: Encodable {
    struct Choice: Encodable {
        struct Message: Encodable {
            let role = "assistant"
            let content: String?
            let refusal: String?
            let toolCalls: [AFMChatToolCallPayload]?

            init(content: String?, refusal: String?, toolCalls: [AFMChatToolCall]) {
                self.content = content
                self.refusal = refusal
                self.toolCalls = toolCalls.isEmpty ? nil : toolCalls.map(AFMChatToolCallPayload.init)
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(role, forKey: .role)
                try container.encodeIfPresentOrNil(content, forKey: .content)
                try container.encodeIfPresentOrNil(refusal, forKey: .refusal)
                try container.encodeIfPresent(toolCalls, forKey: .toolCalls)
            }

            private enum CodingKeys: String, CodingKey {
                case role
                case content
                case refusal
                case toolCalls = "tool_calls"
            }
        }

        let index: Int
        let message: Message
        let finishReason: AFMChatFinishReason

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(index, forKey: .index)
            try container.encode(message, forKey: .message)
            try container.encodeNil(forKey: .logprobs)
            try container.encode(finishReason, forKey: .finishReason)
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case message
            case logprobs
            case finishReason = "finish_reason"
        }
    }

    let id: String
    let object = "chat.completion"
    let created: Int64
    let model: String
    let choices: [Choice]
    let usage: AFMChatUsagePayload
}

struct AFMChatUsagePayload: Encodable {
    struct PromptDetails: Encodable {
        let cachedTokens: Int?

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresentOrNil(cachedTokens, forKey: .cachedTokens)
        }

        private enum CodingKeys: String, CodingKey {
            case cachedTokens = "cached_tokens"
        }
    }

    struct CompletionDetails: Encodable {
        let reasoningTokens: Int?

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresentOrNil(reasoningTokens, forKey: .reasoningTokens)
        }

        private enum CodingKeys: String, CodingKey {
            case reasoningTokens = "reasoning_tokens"
        }
    }

    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int
    let promptTokensDetails: PromptDetails
    let completionTokensDetails: CompletionDetails
    let measurement: ModelTokenUsage.Measurement
    let scope: ModelTokenUsage.Scope

    init(_ usage: ModelTokenUsage) {
        promptTokens = usage.input.totalTokenCount
        completionTokens = usage.output?.totalTokenCount ?? 0
        totalTokens = usage.totalTokenCount
        promptTokensDetails = .init(cachedTokens: usage.input.cachedTokenCount)
        completionTokensDetails = .init(reasoningTokens: usage.output?.reasoningTokenCount)
        measurement = usage.measurement
        scope = usage.scope
    }

    private enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptTokensDetails = "prompt_tokens_details"
        case completionTokensDetails = "completion_tokens_details"
        case measurement = "afm_measurement"
        case scope = "afm_scope"
    }
}

private extension KeyedEncodingContainer {
    mutating func encodeIfPresentOrNil<T: Encodable>(_ value: T?, forKey key: Key) throws {
        if let value {
            try encode(value, forKey: key)
        } else {
            try encodeNil(forKey: key)
        }
    }
}
