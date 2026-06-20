import Foundation

public enum FoundationLabExperimentKind: String, CaseIterable, Codable, Hashable, Sendable {
    case conversation
    case generation
    case structuredOutput
    case toolUse
    case applied
    case evaluation

    public var displayName: String {
        switch self {
        case .conversation:
            String(localized: "Conversation")
        case .generation:
            String(localized: "Generation")
        case .structuredOutput:
            String(localized: "Structured Output")
        case .toolUse:
            String(localized: "Tool Use")
        case .applied:
            String(localized: "Applied")
        case .evaluation:
            String(localized: "Evaluation")
        }
    }

    public var systemImage: String {
        switch self {
        case .conversation:
            "bubble.left.and.bubble.right"
        case .generation:
            "text.sparkle"
        case .structuredOutput:
            "curlybraces"
        case .toolUse:
            "wrench.and.screwdriver"
        case .applied:
            "app.badge"
        case .evaluation:
            "checkmark.seal"
        }
    }
}
