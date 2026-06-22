import Foundation

extension AFMChatMessage: Decodable {
    private static let allowedFields: Set<String> = [
        "role", "content", "name", "tool_call_id", "tool_calls", "reasoning_content"
    ]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        try rejectUnsupportedFields(["reasoning_content"], in: container, decoder: decoder)

        guard container.contains(.init("role")) else {
            throw AFMChatRequestValidationError.missingField(parameterPath(decoder.codingPath, field: "role"))
        }
        let roleValue = try container.decode(String.self, forKey: .init("role"))
        guard let role = AFMChatRole(rawValue: roleValue) else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "role"),
                message: "Unsupported message role '\(roleValue)'."
            )
        }

        let content = try container.decodeIfPresent(AFMChatContent.self, forKey: .init("content"))
        let name = try container.decodeIfPresent(String.self, forKey: .init("name"))
        let toolCallID = try container.decodeIfPresent(String.self, forKey: .init("tool_call_id"))
        let toolCalls = try container.decodeIfPresent([AFMChatToolCall].self, forKey: .init("tool_calls")) ?? []
        let fields = AFMChatMessageFields(
            role: role,
            content: content,
            name: name,
            toolCallID: toolCallID,
            toolCalls: toolCalls
        )
        try Self.validateRoleFields(fields, codingPath: decoder.codingPath)

        self.init(
            role: role,
            contentSegments: content?.segments,
            name: name,
            toolCallID: toolCallID,
            toolCalls: toolCalls
        )
    }

    private static func validateRoleFields(
        _ fields: AFMChatMessageFields,
        codingPath: [any CodingKey]
    ) throws {
        switch fields.role {
        case .system, .developer, .user:
            try requireContent(fields.content, codingPath: codingPath)
            try rejectToolFields(
                name: fields.name,
                toolCallID: fields.toolCallID,
                toolCalls: fields.toolCalls,
                codingPath: codingPath
            )
        case .assistant:
            guard fields.content?.hasMeaningfulText == true || !fields.toolCalls.isEmpty else {
                throw AFMChatRequestValidationError.invalidField(
                    parameterPath(codingPath, field: "content"),
                    message: "Assistant messages require content or tool_calls."
                )
            }
            if fields.name != nil {
                throw AFMChatRequestValidationError.unsupportedField(parameterPath(codingPath, field: "name"))
            }
            if fields.toolCallID != nil {
                throw AFMChatRequestValidationError.unsupportedField(
                    parameterPath(codingPath, field: "tool_call_id")
                )
            }
        case .tool:
            try requireContent(fields.content, codingPath: codingPath)
            guard let toolCallID = fields.toolCallID, !toolCallID.isEmpty else {
                throw AFMChatRequestValidationError.missingField(parameterPath(codingPath, field: "tool_call_id"))
            }
            guard fields.toolCalls.isEmpty else {
                throw AFMChatRequestValidationError.unsupportedField(parameterPath(codingPath, field: "tool_calls"))
            }
            if let name = fields.name, name.isEmpty {
                throw AFMChatRequestValidationError.invalidField(
                    parameterPath(codingPath, field: "name"),
                    message: "Tool names cannot be empty."
                )
            }
        }
    }

    private static func requireContent(_ content: AFMChatContent?, codingPath: [any CodingKey]) throws {
        guard content?.hasMeaningfulText == true else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(codingPath, field: "content"),
                message: "Message content must contain non-empty text."
            )
        }
    }

    private static func rejectToolFields(
        name: String?,
        toolCallID: String?,
        toolCalls: [AFMChatToolCall],
        codingPath: [any CodingKey]
    ) throws {
        if name != nil {
            throw AFMChatRequestValidationError.unsupportedField(parameterPath(codingPath, field: "name"))
        }
        if toolCallID != nil {
            throw AFMChatRequestValidationError.unsupportedField(parameterPath(codingPath, field: "tool_call_id"))
        }
        if !toolCalls.isEmpty {
            throw AFMChatRequestValidationError.unsupportedField(parameterPath(codingPath, field: "tool_calls"))
        }
    }
}

private struct AFMChatMessageFields {
    let role: AFMChatRole
    let content: AFMChatContent?
    let name: String?
    let toolCallID: String?
    let toolCalls: [AFMChatToolCall]
}

extension AFMChatToolCall: Decodable {
    private static let allowedFields: Set<String> = ["id", "type", "function"]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        let id = try container.decode(String.self, forKey: .init("id"))
        let type = try container.decode(String.self, forKey: .init("type"))
        guard type == "function" else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "Only function tool calls are supported in message history."
            )
        }
        let function = try container.decode(AFMChatToolFunction.self, forKey: .init("function"))
        guard !id.isEmpty else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "id"),
                message: "Tool call IDs cannot be empty."
            )
        }
        self.init(id: id, name: function.name, arguments: function.arguments)
    }
}

private struct AFMChatToolFunction: Decodable {
    let name: String
    let arguments: String

    private static let allowedFields: Set<String> = ["name", "arguments"]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        name = try container.decode(String.self, forKey: .init("name"))
        arguments = try container.decode(String.self, forKey: .init("arguments"))
        guard !name.isEmpty else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "name"),
                message: "Tool names cannot be empty."
            )
        }
        guard arguments.isJSONObject else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "arguments"),
                message: "Tool arguments must be a JSON object encoded as a string."
            )
        }
    }
}

private struct AFMChatContent: Decodable {
    let segments: [String]

    var hasMeaningfulText: Bool {
        segments.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            segments = [value]
            return
        }
        do {
            let parts = try container.decode([AFMChatContentPart].self)
            guard !parts.isEmpty else {
                throw AFMChatRequestValidationError.invalidField(
                    parameterPath(decoder.codingPath),
                    message: "Content arrays cannot be empty."
                )
            }
            segments = parts.map(\.text)
            return
        } catch let error as AFMChatRequestValidationError {
            throw error
        } catch {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath),
                message: "Content must be a string or an array of text parts."
            )
        }
    }
}

private struct AFMChatContentPart: Decodable {
    let text: String

    private static let allowedFields: Set<String> = ["type", "text", "image_url"]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        if container.contains(.init("image_url")), try !container.decodeNil(forKey: .init("image_url")) {
            throw AFMChatRequestValidationError.unsupportedField(
                parameterPath(decoder.codingPath, field: "image_url")
            )
        }
        let type = try container.decode(String.self, forKey: .init("type"))
        guard type == "text" else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "Only text content parts are supported by this endpoint."
            )
        }
        text = try container.decode(String.self, forKey: .init("text"))
    }
}

private extension String {
    var isJSONObject: Bool {
        guard let data = data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data),
              object is [String: Any] else {
            return false
        }
        return true
    }
}
