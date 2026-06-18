//
//  ToolApprovalCodeExample.swift
//  FoundationLab
//

import Foundation

enum ToolApprovalCodeExample {
    static let source = #"""
    import FoundationModels

    struct SendMessageTool: Tool {
        let name = "sendMessage"
        let description = "Send a reviewed message to a known recipient"
        let approval: MessageApproval
        let sender: MessageSender

        @Generable
        struct Arguments {
            let recipientID: String
            let body: String
        }

        func call(arguments: Arguments) async throws -> String {
            // These are app checks. A model-generated call is not authorization.
            let message = try sender.validate(arguments)
            guard await approval.request(for: message) else {
                throw ToolAuthorizationError.denied
            }
            return try await sender.send(message)
        }
    }
    """#
}
