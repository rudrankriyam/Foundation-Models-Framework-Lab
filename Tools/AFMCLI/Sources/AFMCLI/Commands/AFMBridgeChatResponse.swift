import FoundationModelsKit

struct AFMBridgeChatResponse: Decodable, Sendable {
    struct Choice: Decodable, Sendable {
        struct Message: Decodable, Sendable {
            let role: String
            let content: String?
            let refusal: String?
        }

        let index: Int
        let message: Message
        let finishReason: String

        private enum CodingKeys: String, CodingKey {
            case index
            case message
            case finishReason = "finish_reason"
        }
    }

    struct Usage: Decodable, Sendable {
        struct PromptDetails: Decodable, Sendable {
            let cachedTokens: Int?

            private enum CodingKeys: String, CodingKey {
                case cachedTokens = "cached_tokens"
            }
        }

        struct CompletionDetails: Decodable, Sendable {
            let reasoningTokens: Int?

            private enum CodingKeys: String, CodingKey {
                case reasoningTokens = "reasoning_tokens"
            }
        }

        let promptTokens: Int
        let completionTokens: Int
        let totalTokens: Int
        let promptDetails: PromptDetails
        let completionDetails: CompletionDetails
        let measurement: ModelTokenUsage.Measurement
        let scope: ModelTokenUsage.Scope

        var tokenUsage: ModelTokenUsage {
            ModelTokenUsage(
                input: .init(totalTokenCount: promptTokens, cachedTokenCount: promptDetails.cachedTokens),
                output: .init(
                    totalTokenCount: completionTokens,
                    reasoningTokenCount: completionDetails.reasoningTokens
                ),
                measurement: measurement,
                scope: scope
            )
        }

        private enum CodingKeys: String, CodingKey {
            case promptTokens = "prompt_tokens"
            case completionTokens = "completion_tokens"
            case totalTokens = "total_tokens"
            case promptDetails = "prompt_tokens_details"
            case completionDetails = "completion_tokens_details"
            case measurement = "afm_measurement"
            case scope = "afm_scope"
        }
    }

    let id: String
    let object: String
    let created: Int64
    let model: String
    let choices: [Choice]
    let usage: Usage
}
