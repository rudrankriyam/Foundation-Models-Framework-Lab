import Foundation
import FoundationModels
import FoundationModelsTools

public struct ConfirmedContactsTool: Tool {
    public typealias Arguments = ContactsTool.Arguments

    public let name = "manageContacts"
    public let description = "Search and read contacts, or create a contact after host-app confirmation"

    private let contactsTool = ContactsTool()
    private let mutationConfirmation: (any ToolMutationConfirming)?

    public init(mutationConfirmation: (any ToolMutationConfirming)?) {
        self.mutationConfirmation = mutationConfirmation
    }

    public func call(arguments: Arguments) async throws -> GeneratedContent {
        let firstName = arguments.firstName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard arguments.action.lowercased() == "create", !firstName.isEmpty else {
            return try await contactsTool.call(arguments: arguments)
        }

        let request = ToolMutationRequest(
            toolName: name,
            action: "create",
            summary: "Create contact '\(fullName(arguments))'",
            details: details(arguments)
        )
        guard let mutationConfirmation else {
            throw ToolMutationExecutionError.confirmationRequired(for: request)
        }

        let contactsTool = contactsTool
        let content = arguments.generatedContent
        return try await ToolMutationExecutor(confirmer: mutationConfirmation)
            .execute(request) { try await contactsTool.call(arguments: Arguments(content)) }
            .value
    }

    private func fullName(_ arguments: Arguments) -> String {
        [arguments.firstName, arguments.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func details(_ arguments: Arguments) -> [ToolMutationDetail] {
        [
            ("First Name", arguments.firstName),
            ("Last Name", arguments.lastName),
            ("Phone", arguments.phoneNumber),
            ("Email", arguments.email),
            ("Organization", arguments.organization)
        ].compactMap { label, value in
            guard let value, !value.isEmpty else { return nil }
            return ToolMutationDetail(label: label, value: value)
        }
    }
}
