import Foundation

struct AFMChatCompletionChunk: Encodable {
    struct Choice: Encodable {
        struct Delta: Encodable {
            let role: String?
            let content: String?
            let refusal: String?

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeIfPresent(role, forKey: .role)
                try container.encodeIfPresent(content, forKey: .content)
                try container.encodeIfPresent(refusal, forKey: .refusal)
            }

            private enum CodingKeys: String, CodingKey {
                case role
                case content
                case refusal
            }
        }

        let index: Int
        let delta: Delta
        let finishReason: AFMChatFinishReason?

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(index, forKey: .index)
            try container.encode(delta, forKey: .delta)
            try container.encodeNil(forKey: .logprobs)
            if let finishReason {
                try container.encode(finishReason, forKey: .finishReason)
            } else {
                try container.encodeNil(forKey: .finishReason)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case index
            case delta
            case logprobs
            case finishReason = "finish_reason"
        }
    }

    let id: String
    let object = "chat.completion.chunk"
    let created: Int64
    let model: String
    let choices: [Choice]
    let usage: AFMChatUsagePayload?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(object, forKey: .object)
        try container.encode(created, forKey: .created)
        try container.encode(model, forKey: .model)
        try container.encode(choices, forKey: .choices)
        if let usage {
            try container.encode(usage, forKey: .usage)
        } else {
            try container.encodeNil(forKey: .usage)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case object
        case created
        case model
        case choices
        case usage
    }
}
