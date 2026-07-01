import Foundation
import FoundationModelsKit

public enum ReminderPriorityValue: String, CaseIterable, Sendable, Hashable, Codable {
    case none
    case low
    case medium
    case high

    public var displayName: String {
        switch self {
        case .none:
            return "None"
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
}
