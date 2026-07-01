import Foundation
import FoundationModelsKit
public enum ReminderExecutionMode: String, Sendable, Hashable, Codable {
    case customPrompt
    case quickCreate
}

public struct ManageRemindersRequest: FoundationModelCapabilityRequest, Sendable {
    public let mode: ReminderExecutionMode
    public let customPrompt: String?
    public let title: String?
    public let notes: String?
    public let dueDate: Date?
    public let priority: ReminderPriorityValue
    public let listName: String?
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let referenceDate: Date
    public let timeZoneIdentifier: String
    public let context: FoundationModelInvocationContext

    public init(
        mode: ReminderExecutionMode,
        customPrompt: String? = nil,
        title: String? = nil,
        notes: String? = nil,
        dueDate: Date? = nil,
        priority: ReminderPriorityValue = .none,
        listName: String? = nil,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        referenceDate: Date = .now,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        context: FoundationModelInvocationContext
    ) {
        self.mode = mode
        self.customPrompt = customPrompt
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.priority = priority
        self.listName = listName
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.referenceDate = referenceDate
        self.timeZoneIdentifier = timeZoneIdentifier
        self.context = context
    }
}
