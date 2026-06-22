import Foundation
import FoundationModelsKit

extension AFMChatGenerationRequest {
    static func validateTools(
        _ tools: [AFMChatToolDefinition],
        choice: AFMChatToolChoice,
        parallelToolCalls: Bool
    ) throws {
        guard tools.count <= AFMChatToolLimits.maximumDefinitions else {
            throw AFMChatRequestValidationError.invalidField(
                "tools",
                message: "At most \(AFMChatToolLimits.maximumDefinitions) tools may be provided."
            )
        }
        if !parallelToolCalls, !tools.isEmpty, choice != .none {
            throw AFMChatRequestValidationError.unsupportedField("parallel_tool_calls")
        }

        let names = try validateToolDefinitions(tools)
        try validateToolChoice(choice, declaredNames: names, hasTools: !tools.isEmpty)
    }

    static func validateToolChoiceAvailability(_ choice: AFMChatToolChoice) throws {
        guard choice.requiresInvocation else { return }
        #if compiler(>=6.4)
        guard #available(iOS 27.0, macOS 27.0, *) else {
            throw unsupportedToolChoice()
        }
        #else
        throw unsupportedToolChoice()
        #endif
    }

    private static func unsupportedToolChoice() -> AFMChatRequestValidationError {
        .init(
            message: "This OS cannot guarantee the requested tool_choice semantics.",
            parameter: "tool_choice",
            code: "unsupported_tool_choice"
        )
    }

    private static func validateToolDefinitions(
        _ tools: [AFMChatToolDefinition]
    ) throws -> Set<String> {
        var names = Set<String>()
        var totalSchemaBytes = 0
        for (index, tool) in tools.enumerated() {
            let basePath = "tools[\(index)].function"
            try validateToolName(tool.name, at: "\(basePath).name")
            guard names.insert(tool.name).inserted else {
                throw AFMChatRequestValidationError.invalidField(
                    "\(basePath).name",
                    message: "Tool names must be unique."
                )
            }
            guard tool.description.utf8.count <= AFMChatToolLimits.maximumDescriptionBytes else {
                throw AFMChatRequestValidationError.invalidField(
                    "\(basePath).description",
                    message: "Tool descriptions may not exceed \(AFMChatToolLimits.maximumDescriptionBytes) UTF-8 bytes."
                )
            }
            let parametersPath = "\(basePath).parameters"
            totalSchemaBytes += try validateToolSchema(tool.parameters, at: parametersPath)
            if tool.strict == true {
                try validateStrictToolSchema(tool.parameters, at: parametersPath)
            }
        }
        guard totalSchemaBytes <= AFMChatToolLimits.maximumTotalSchemaBytes else {
            throw AFMChatRequestValidationError.invalidField(
                "tools",
                message: "Combined tool schemas may not exceed \(AFMChatToolLimits.maximumTotalSchemaBytes) bytes."
            )
        }
        return names
    }

    private static func validateToolChoice(
        _ choice: AFMChatToolChoice,
        declaredNames: Set<String>,
        hasTools: Bool
    ) throws {
        switch choice {
        case .required where !hasTools:
            throw AFMChatRequestValidationError.invalidField(
                "tool_choice",
                message: "tool_choice 'required' requires at least one tool."
            )
        case .function(let name):
            try validateToolName(name, at: "tool_choice.function.name")
            guard declaredNames.contains(name) else {
                throw AFMChatRequestValidationError.invalidField(
                    "tool_choice.function.name",
                    message: "The selected function must match a declared tool."
                )
            }
        case .auto, .none, .required:
            break
        }
    }

    private static func validateToolSchema(
        _ schema: FoundationModelsJSONSchema,
        at path: String
    ) throws -> Int {
        do {
            try schema.validate()
            guard try schema.resolvedType() == .object else {
                throw FoundationModelsJSONSchemaError(
                    kind: .invalidSchema,
                    path: "$.type",
                    message: "Tool parameter schemas must have an object root."
                )
            }
            let schemaBytes = try schema.jsonData().count
            guard schemaBytes <= AFMChatToolLimits.maximumSchemaBytes else {
                throw AFMChatRequestValidationError.invalidField(
                    path,
                    message: "Each tool schema may not exceed \(AFMChatToolLimits.maximumSchemaBytes) bytes."
                )
            }
            return schemaBytes
        } catch let error as FoundationModelsJSONSchemaError {
            throw AFMChatRequestValidationError.toolSchema(error, parameter: path)
        }
    }

    private static func validateToolName(_ name: String, at path: String) throws {
        let isValid = (1...64).contains(name.utf8.count) && name.utf8.allSatisfy { byte in
            byte.isASCIILetter || byte.isASCIIDigit || byte == 45 || byte == 95
        }
        guard isValid else {
            throw AFMChatRequestValidationError.invalidField(
                path,
                message: "Tool names must contain 1-64 ASCII letters, digits, hyphens, or underscores."
            )
        }
    }

    private static func validateStrictToolSchema(
        _ schema: FoundationModelsJSONSchema,
        at path: String
    ) throws {
        switch try schema.resolvedType() {
        case .object:
            guard schema.additionalProperties == false else {
                throw strictToolSchemaError(
                    at: "\(path).additionalProperties",
                    message: "Strict tool schemas must set additionalProperties to false for every object."
                )
            }
            let required = Set(schema.required ?? [])
            if let optionalProperty = (schema.properties ?? [:]).keys.sorted().first(where: { !required.contains($0) }) {
                throw strictToolSchemaError(
                    at: "\(path).required",
                    message: "Strict tool schemas must list property '\(optionalProperty)' as required."
                )
            }
            for propertyName in (schema.properties ?? [:]).keys.sorted() {
                guard let property = schema.properties?[propertyName] else { continue }
                try validateStrictToolSchema(
                    property,
                    at: appendSchemaPath("\(path).properties", component: propertyName)
                )
            }
        case .array:
            if let items = schema.items {
                try validateStrictToolSchema(items, at: "\(path).items")
            }
        case .string, .integer, .number, .boolean:
            break
        }
    }

    private static func strictToolSchemaError(
        at path: String,
        message: String
    ) -> AFMChatRequestValidationError {
        .init(message: message, parameter: path, code: "invalid_tool_schema")
    }

    private static func appendSchemaPath(_ path: String, component: String) -> String {
        let isIdentifier = component.first?.isLetter == true
            && component.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        guard !isIdentifier else { return "\(path).\(component)" }
        let escaped = component
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\(path)[\"\(escaped)\"]"
    }

    static func validateMessages(_ messages: [AFMChatMessage]) throws {
        guard !messages.isEmpty else {
            throw AFMChatRequestValidationError.invalidField(
                "messages",
                message: "At least one message is required."
            )
        }

        var hasConversationStarted = false
        var pendingToolCalls: [String: String] = [:]
        var seenToolCallIDs: Set<String> = []
        for (index, message) in messages.enumerated() {
            let basePath = "messages[\(index)]"
            if message.role == .system || message.role == .developer {
                guard !hasConversationStarted else {
                    throw AFMChatRequestValidationError.invalidField(
                        "\(basePath).role",
                        message: "System and developer messages must precede conversation history."
                    )
                }
                continue
            }

            hasConversationStarted = true
            if message.role != .tool, !pendingToolCalls.isEmpty {
                throw AFMChatRequestValidationError.invalidField(
                    "\(basePath).role",
                    message: "Tool responses must immediately follow their assistant tool calls."
                )
            }
            try registerToolCalls(
                message.toolCalls,
                at: basePath,
                pending: &pendingToolCalls,
                seen: &seenToolCallIDs
            )
            if message.role == .tool {
                try consumeToolOutput(message, at: basePath, pending: &pendingToolCalls)
            }
        }

        guard pendingToolCalls.isEmpty else {
            throw AFMChatRequestValidationError.invalidField(
                "messages",
                message: "Every assistant tool call must have a matching tool response."
            )
        }
        guard let finalRole = messages.last?.role, finalRole == .user || finalRole == .tool else {
            throw AFMChatRequestValidationError.invalidField(
                "messages",
                message: "The final message must have role 'user' or 'tool'."
            )
        }
    }

    private static func registerToolCalls(
        _ calls: [AFMChatToolCall],
        at basePath: String,
        pending: inout [String: String],
        seen: inout Set<String>
    ) throws {
        for (index, call) in calls.enumerated() {
            guard seen.insert(call.id).inserted else {
                throw AFMChatRequestValidationError.invalidField(
                    "\(basePath).tool_calls[\(index)].id",
                    message: "Tool call IDs must be unique."
                )
            }
            pending[call.id] = call.name
        }
    }

    private static func consumeToolOutput(
        _ message: AFMChatMessage,
        at basePath: String,
        pending: inout [String: String]
    ) throws {
        guard let toolCallID = message.toolCallID,
              let expectedName = pending.removeValue(forKey: toolCallID) else {
            throw AFMChatRequestValidationError.invalidField(
                "\(basePath).tool_call_id",
                message: "Tool responses must reference an earlier unmatched tool call."
            )
        }
        if let name = message.name, name != expectedName {
            throw AFMChatRequestValidationError.invalidField(
                "\(basePath).name",
                message: "Tool response name does not match its tool call."
            )
        }
    }
}

private extension UInt8 {
    var isASCIILetter: Bool {
        (65...90).contains(self) || (97...122).contains(self)
    }

    var isASCIIDigit: Bool {
        (48...57).contains(self)
    }
}
