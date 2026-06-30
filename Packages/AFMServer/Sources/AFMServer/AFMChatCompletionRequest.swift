import Foundation
import FoundationModelsKit

public enum AFMChatRole: String, Sendable, Equatable {
    case system
    case developer
    case user
    case assistant
    case tool
}

public struct AFMChatToolCall: Sendable, Equatable {
    public let id: String
    public let name: String
    public let arguments: String

    public init(id: String, name: String, arguments: String) {
        self.id = id
        self.name = name
        self.arguments = arguments
    }
}

public struct AFMChatMessage: Sendable, Equatable {
    public let role: AFMChatRole
    public let contentSegments: [String]?
    public let name: String?
    public let toolCallID: String?
    public let toolCalls: [AFMChatToolCall]

    public init(
        role: AFMChatRole,
        contentSegments: [String]? = nil,
        name: String? = nil,
        toolCallID: String? = nil,
        toolCalls: [AFMChatToolCall] = []
    ) {
        self.role = role
        self.contentSegments = contentSegments
        self.name = name
        self.toolCallID = toolCallID
        self.toolCalls = toolCalls
    }
}

public enum AFMChatReasoningLevel: String, Sendable, Equatable {
    case none
    case light
    case moderate
    case deep
}

public struct AFMChatGenerationRequest: Sendable, Equatable {
    public let model: String
    public let messages: [AFMChatMessage]
    public let stream: Bool
    public let streamOptions: AFMChatStreamOptions?
    public let temperature: Double?
    public let topP: Double?
    public let maximumCompletionTokens: Int?
    public let responseFormat: AFMChatResponseFormat?
    public let tools: [AFMChatToolDefinition]
    public let toolChoice: AFMChatToolChoice
    public let parallelToolCalls: Bool
    public let reasoningLevel: AFMChatReasoningLevel?

    public init(
        model: String = "system",
        messages: [AFMChatMessage],
        stream: Bool = false,
        streamOptions: AFMChatStreamOptions? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        maximumCompletionTokens: Int? = nil,
        responseFormat: AFMChatResponseFormat? = nil,
        tools: [AFMChatToolDefinition] = [],
        parallelToolCalls: Bool = true,
        reasoningLevel: AFMChatReasoningLevel? = nil
    ) {
        self.init(
            model: model,
            messages: messages,
            stream: stream,
            streamOptions: streamOptions,
            temperature: temperature,
            topP: topP,
            maximumCompletionTokens: maximumCompletionTokens,
            responseFormat: responseFormat,
            tools: tools,
            toolChoice: tools.isEmpty ? .none : .auto,
            parallelToolCalls: parallelToolCalls,
            reasoningLevel: reasoningLevel
        )
    }

    public init(
        model: String = "system",
        messages: [AFMChatMessage],
        stream: Bool = false,
        streamOptions: AFMChatStreamOptions? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        maximumCompletionTokens: Int? = nil,
        responseFormat: AFMChatResponseFormat? = nil,
        tools: [AFMChatToolDefinition] = [],
        toolChoice: AFMChatToolChoice,
        parallelToolCalls: Bool = true,
        reasoningLevel: AFMChatReasoningLevel? = nil
    ) {
        self.model = model
        self.messages = messages
        self.stream = stream
        self.streamOptions = streamOptions
        self.temperature = temperature
        self.topP = topP
        self.maximumCompletionTokens = maximumCompletionTokens
        self.responseFormat = responseFormat
        self.tools = tools
        self.toolChoice = toolChoice
        self.parallelToolCalls = parallelToolCalls
        self.reasoningLevel = reasoningLevel
    }
}

extension AFMChatReasoningLevel: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self).lowercased()
        switch value {
        case "none", "default":
            self = .none
        case "light", "low":
            self = .light
        case "moderate", "medium":
            self = .moderate
        case "deep", "high":
            self = .deep
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Reasoning level must be one of none, low, medium, or high."
            )
        }
    }
}

extension AFMChatGenerationRequest: Decodable {
    private static let allowedFields: Set<String> = [
        "model", "messages", "stream", "temperature", "top_p",
        "max_completion_tokens", "max_tokens", "tools", "tool_choice",
        "parallel_tool_calls", "response_format", "stream_options",
        "reasoning_level"
    ]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)

        let model = try container.decodeIfPresent(String.self, forKey: .init("model")) ?? "system"
        guard container.contains(.init("messages")) else {
            throw AFMChatRequestValidationError.missingField("messages")
        }
        let messages = try container.decode([AFMChatMessage].self, forKey: .init("messages"))
        let stream = try container.decodeIfPresent(Bool.self, forKey: .init("stream")) ?? false
        let streamOptions = try container.decodeIfPresent(
            AFMChatStreamOptions.self,
            forKey: .init("stream_options")
        )
        let temperature = try container.decodeIfPresent(Double.self, forKey: .init("temperature"))
        let topP = try container.decodeIfPresent(Double.self, forKey: .init("top_p"))
        let maximumCompletionTokens = try container.decodeIfPresent(
            Int.self,
            forKey: .init("max_completion_tokens")
        )
        let legacyMaximumTokens = try container.decodeIfPresent(Int.self, forKey: .init("max_tokens"))
        let responseFormat = try container.decodeIfPresent(
            AFMChatResponseFormat.self,
            forKey: .init("response_format")
        )
        let tools = try container.decodeIfPresent([AFMChatToolDefinition].self, forKey: .init("tools")) ?? []
        let explicitToolChoice = try container.decodeIfPresent(AFMChatToolChoice.self, forKey: .init("tool_choice"))
        let toolChoice = explicitToolChoice ?? (tools.isEmpty ? .none : .auto)
        let parallelToolCalls = try container.decodeIfPresent(
            Bool.self,
            forKey: .init("parallel_tool_calls")
        ) ?? true
        let reasoningLevel = try container.decodeIfPresent(
            AFMChatReasoningLevel.self,
            forKey: .init("reasoning_level")
        )

        try Self.validateModel(model)
        try Self.validateStreaming(stream: stream, streamOptions: streamOptions)
        try Self.validateTools(
            tools,
            choice: toolChoice,
            parallelToolCalls: parallelToolCalls
        )
        try Self.validateToolChoiceAvailability(toolChoice)
        try Self.validateOptions(
            temperature: temperature,
            topP: topP,
            maximumCompletionTokens: maximumCompletionTokens,
            legacyMaximumTokens: legacyMaximumTokens
        )
        try Self.validateMessages(messages)

        self.init(
            model: model,
            messages: messages,
            stream: stream,
            streamOptions: streamOptions,
            temperature: temperature,
            topP: topP,
            maximumCompletionTokens: maximumCompletionTokens ?? legacyMaximumTokens,
            responseFormat: responseFormat,
            tools: tools,
            toolChoice: toolChoice,
            parallelToolCalls: parallelToolCalls,
            reasoningLevel: reasoningLevel
        )
    }

    static func decode(_ data: Data) throws -> Self {
        do {
            return try JSONDecoder().decode(Self.self, from: data)
        } catch let error as AFMChatRequestValidationError {
            throw error
        } catch let error as DecodingError {
            throw AFMChatRequestValidationError(decodingError: error)
        } catch {
            throw AFMChatRequestValidationError.malformedJSON
        }
    }

    private static func validateModel(_ model: String) throws {
        guard !model.isEmpty, model == model.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw AFMChatRequestValidationError.invalidField("model", message: "Model must be a non-empty identifier.")
        }
    }

    private static func validateStreaming(
        stream: Bool,
        streamOptions: AFMChatStreamOptions?
    ) throws {
        guard stream || streamOptions == nil else {
            throw AFMChatRequestValidationError.invalidField(
                "stream_options",
                message: "stream_options may only be used when stream is true."
            )
        }
    }

    private static func validateOptions(
        temperature: Double?,
        topP: Double?,
        maximumCompletionTokens: Int?,
        legacyMaximumTokens: Int?
    ) throws {
        if let temperature, !temperature.isFinite || !(0...1).contains(temperature) {
            throw AFMChatRequestValidationError.invalidField(
                "temperature",
                message: "Temperature must be between 0 and 1."
            )
        }
        if let topP, !topP.isFinite || topP <= 0 || topP > 1 {
            throw AFMChatRequestValidationError.invalidField("top_p", message: "top_p must be greater than 0 and at most 1.")
        }
        if maximumCompletionTokens != nil, legacyMaximumTokens != nil {
            throw AFMChatRequestValidationError.invalidField(
                "max_tokens",
                message: "Use either max_completion_tokens or max_tokens, not both."
            )
        }
        if let maximumTokens = maximumCompletionTokens ?? legacyMaximumTokens, maximumTokens <= 0 {
            let parameter = maximumCompletionTokens == nil ? "max_tokens" : "max_completion_tokens"
            throw AFMChatRequestValidationError.invalidField(parameter, message: "The token limit must be greater than zero.")
        }
    }
}

struct AFMChatRequestValidationError: Error, Equatable, Sendable {
    let message: String
    let parameter: String?
    let code: String

    static let malformedJSON = Self(
        message: "The request body must be a valid JSON object.",
        parameter: nil,
        code: "invalid_json"
    )

    static func missingField(_ parameter: String) -> Self {
        .init(message: "Missing required field '\(parameter)'.", parameter: parameter, code: "missing_field")
    }

    static func invalidField(_ parameter: String, message: String) -> Self {
        .init(message: message, parameter: parameter, code: "invalid_field")
    }

    static func unsupportedField(_ parameter: String) -> Self {
        .init(
            message: "Field '\(parameter)' is not supported by this chat completions endpoint.",
            parameter: parameter,
            code: "unsupported_field"
        )
    }

    static func unknownField(_ parameter: String) -> Self {
        .init(message: "Unknown field '\(parameter)'.", parameter: parameter, code: "unknown_field")
    }

    static func toolSchema(
        _ error: FoundationModelsJSONSchemaError,
        parameter: String
    ) -> Self {
        let suffix = error.path == "$" ? "" : String(error.path.dropFirst())
        return .init(
            message: error.message,
            parameter: parameter + suffix,
            code: error.kind == .unsupportedKeyword ? "unsupported_schema_keyword" : "invalid_tool_schema"
        )
    }
}
