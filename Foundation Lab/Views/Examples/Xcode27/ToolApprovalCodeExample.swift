//
//  ToolApprovalCodeExample.swift
//  FoundationLab
//

import Foundation

enum ToolApprovalCodeExample {
    static let source = #"""
    import FoundationModels

    struct ReviewedMessage: Sendable {
        let recipientID: String
        let body: String
    }

    protocol MessageApproval: Sendable {
        func request(for message: ReviewedMessage) async -> Bool
    }

    protocol MessageSender: Sendable {
        func validate(recipientID: String, body: String) throws -> ReviewedMessage
        func send(_ message: ReviewedMessage) async throws -> String
    }

    enum ToolAuthorizationError: Error {
        case denied
    }

    struct SendMessageTool: Tool {
        let name = "sendMessage"
        let description = "Send a reviewed message to a known recipient"
        let approval: any MessageApproval
        let sender: any MessageSender

        @Generable
        struct Arguments {
            let recipientID: String
            let body: String
        }

        func call(arguments: Arguments) async throws -> String {
            // These are app checks. A model-generated call is not authorization.
            let message = try sender.validate(
                recipientID: arguments.recipientID,
                body: arguments.body
            )
            guard await approval.request(for: message) else {
                throw ToolAuthorizationError.denied
            }
            return try await sender.send(message)
        }
    }
    """#
}
