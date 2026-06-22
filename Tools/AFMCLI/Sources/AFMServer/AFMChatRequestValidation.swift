import Foundation

extension AFMChatGenerationRequest {
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
