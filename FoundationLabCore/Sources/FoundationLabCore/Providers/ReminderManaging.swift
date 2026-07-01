import Foundation
import FoundationModelsKit

public protocol ReminderManaging: Sendable {
    func manageReminders(for request: ManageRemindersRequest) async throws -> FoundationModelTextGenerationResult
}
