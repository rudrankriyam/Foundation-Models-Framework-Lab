import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsReminderManager: ReminderManaging {
    private let toolInvoker: FoundationModelsToolInvoker
    private let mutationConfirmation: any ToolMutationConfirming

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.init(
            mutationConfirmation: DenyingToolMutationConfirmation(),
            toolInvoker: toolInvoker
        )
    }

    public init(
        mutationConfirmation: any ToolMutationConfirming,
        toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()
    ) {
        self.mutationConfirmation = mutationConfirmation
        self.toolInvoker = toolInvoker
    }

    public func manageReminders(for request: ManageRemindersRequest) async throws -> FoundationModelTextGenerationResult {
        let prompt = try prompt(for: request)
        let localeIdentifier = request.context.localeIdentifier ?? Locale.current.identifier
        let formattedDate = FoundationModelsPromptSupport.displayDate(
            request.referenceDate,
            timeZoneIdentifier: request.timeZoneIdentifier,
            localeIdentifier: localeIdentifier
        )
        let timeZone = FoundationModelsPromptSupport.resolvedTimeZone(identifier: request.timeZoneIdentifier)
        let instructions = FoundationModelsPromptSupport.combinedSystemPrompt([
            request.systemPrompt,
            request.mode == .customPrompt
                ? customPromptInstructions(
                    formattedDate: formattedDate,
                    timeZone: timeZone,
                    localeIdentifier: localeIdentifier
                )
                : quickCreateInstructions(
                    formattedDate: formattedDate,
                    timeZone: timeZone,
                    localeIdentifier: localeIdentifier
                )
        ])

        let service = EventKitRemindersService()
        return try await toolInvoker.respond(
            to: prompt,
            using: [
                RemindersReadTool(service: service),
                RemindersMutationTool(
                    service: service,
                    confirmation: mutationConfirmation
                )
            ],
            systemPrompt: instructions,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }

    private func prompt(for request: ManageRemindersRequest) throws -> String {
        switch request.mode {
        case .customPrompt:
            let prompt = request.customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !prompt.isEmpty else {
                throw FoundationLabCoreError.invalidRequest("Missing custom prompt")
            }
            return prompt
        case .quickCreate:
            let title = request.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else {
                throw FoundationLabCoreError.invalidRequest("Missing reminder title")
            }

            var lines = [
                "Create a reminder with the following details:",
                "Title: \(title)"
            ]

            if let notes = request.notes?.trimmingCharacters(in: .whitespacesAndNewlines), !notes.isEmpty {
                lines.append("Notes: \(notes)")
            }

            if let dueDate = request.dueDate {
                lines.append(
                    "Due date: \(FoundationModelsPromptSupport.reminderDateString(dueDate, timeZoneIdentifier: request.timeZoneIdentifier))"
                )
            }

            if request.priority != .none {
                lines.append("Priority: \(request.priority.rawValue)")
            }

            if let listName = request.listName?.trimmingCharacters(in: .whitespacesAndNewlines), !listName.isEmpty {
                lines.append("List: \(listName)")
            }

            return lines.joined(separator: "\n")
        }
    }

    private func customPromptInstructions(
        formattedDate: String,
        timeZone: TimeZone,
        localeIdentifier: String
    ) -> String {
        let timeZoneName = timeZone.localizedName(
            for: .standard,
            locale: Locale(identifier: localeIdentifier)
        ) ?? "Unknown"
        return """
        You are a helpful assistant that can create reminders for users.
        Current date and time: \(formattedDate)
        Time zone: \(timeZone.identifier) (\(timeZoneName))
        When creating reminders, consider the current date and time zone context.
        Call the reminder mutation tool when the request needs a change. The host app will review the exact mutation.
        IMPORTANT: When setting due dates, you MUST format them as 'yyyy-MM-dd HH:mm:ss' (24-hour format).
        Examples: '2025-01-15 17:00:00' for tomorrow at 5 PM, '2025-01-16 09:30:00' for day after tomorrow at 9:30 AM.
        Calculate the exact date and time based on the current date and time provided above.
        """
    }

    private func quickCreateInstructions(
        formattedDate: String,
        timeZone: TimeZone,
        localeIdentifier: String
    ) -> String {
        let timeZoneName = timeZone.localizedName(
            for: .standard,
            locale: Locale(identifier: localeIdentifier)
        ) ?? "Unknown"
        return """
        You are a helpful assistant that creates reminders based on structured input.
        Current date and time: \(formattedDate)
        Time zone: \(timeZone.identifier) (\(timeZoneName))
        Call the reminder mutation tool with the provided information. The host app will review the exact mutation.
        Format due dates as 'yyyy-MM-dd HH:mm:ss' (24-hour format).
        """
    }
}

private struct DenyingToolMutationConfirmation: ToolMutationConfirming {
    func confirmation(for request: ToolMutationRequest) async throws -> ToolMutationDecision {
        .denied(reason: "The host app did not provide a mutation confirmation surface.")
    }
}
