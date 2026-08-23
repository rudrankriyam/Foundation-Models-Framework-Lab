import AppIntents
import Foundation
import FoundationLabCore
import FoundationModelsKit
import FoundationModelsTools

struct ManageRemindersIntent: AppIntent {
    static let title: LocalizedStringResource = "Manage Reminders"
    static let description = IntentDescription(
        "Creates or updates reminders after you approve the change."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Request",
        requestValueDialog: IntentDialog("What would you like to do with reminders?")
    )
    var prompt: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let confirmation = ToolMutationConfirmationHandler { request in
            try await confirm(request)
        }
        let response = try await ManageRemindersUseCase(
            manager: FoundationModelsReminderManager(
                mutationConfirmation: confirmation
            )
        ).execute(
            ManageRemindersRequest(
                mode: .customPrompt,
                customPrompt: prompt,
                referenceDate: .now,
                timeZoneIdentifier: TimeZone.current.identifier,
                context: FoundationModelInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }

    private func confirm(_ request: ToolMutationRequest) async throws -> ToolMutationDecision {
        try await requestConfirmation(
            actionName: confirmationAction(for: request),
            dialog: confirmationDialog(for: request)
        )
        return .approved()
    }

    private func confirmationAction(for request: ToolMutationRequest) -> ConfirmationActionName {
        if request.isDestructive {
            return .custom(
                acceptLabel: "Delete",
                acceptAlternatives: [],
                denyLabel: "Cancel",
                denyAlternatives: [],
                destructive: true
            )
        }

        return request.action == "create" ? .create : .continue
    }

    private func confirmationDialog(for request: ToolMutationRequest) -> IntentDialog {
        let details = request.details
            .map { "\($0.label): \($0.value)" }
            .joined(separator: "\n")
        let supportingText = details.isEmpty
            ? request.summary
            : "\(request.summary)\n\(details)"
        return IntentDialog(
            full: "Proposed tool action",
            supporting: "\(supportingText)"
        )
    }
}
