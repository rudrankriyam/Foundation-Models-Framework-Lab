import Foundation
import FoundationModelsKit

public struct ManageRemindersUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.manage-reminders",
        displayName: "Manage Reminders",
        summary: "Creates and manages reminders using shared Foundation Models orchestration."
    )

    private let manager: any ReminderManaging

    public init(manager: any ReminderManaging = FoundationModelsReminderManager()) {
        self.manager = manager
    }

    public func execute(_ request: ManageRemindersRequest) async throws -> FoundationModelTextGenerationResult {
        switch request.mode {
        case .customPrompt:
            let prompt = request.customPrompt?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !prompt.isEmpty else {
                throw FoundationLabCoreError.invalidRequest("Missing custom prompt")
            }
        case .quickCreate:
            let title = request.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !title.isEmpty else {
                throw FoundationLabCoreError.invalidRequest("Missing reminder title")
            }
        }

        return try await manager.manageReminders(for: request)
    }
}
