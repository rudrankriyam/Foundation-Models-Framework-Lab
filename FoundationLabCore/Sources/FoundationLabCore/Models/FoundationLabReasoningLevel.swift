import Foundation

public enum FoundationLabReasoningLevel: String, CaseIterable, Sendable, Hashable, Codable {
    case none
    case light
    case moderate
    case deep

    public var displayName: String {
        switch self {
        case .none:
            return String(localized: "None")
        case .light:
            return String(localized: "Light")
        case .moderate:
            return String(localized: "Moderate")
        case .deep:
            return String(localized: "Deep")
        }
    }

    public var systemImage: String {
        switch self {
        case .none:
            return "brain"
        case .light:
            return "bolt"
        case .moderate:
            return "brain"
        case .deep:
            return "brain.head.profile"
        }
    }
}
