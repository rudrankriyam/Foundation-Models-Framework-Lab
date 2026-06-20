import Foundation

public enum FoundationLabExperimentLevel: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case beginner
    case intermediate
    case advanced
    case expert

    public var id: Self { self }

    public var displayName: String {
        switch self {
        case .beginner:
            String(localized: "Beginner")
        case .intermediate:
            String(localized: "Intermediate")
        case .advanced:
            String(localized: "Advanced")
        case .expert:
            String(localized: "Expert")
        }
    }

    public var systemImage: String {
        switch self {
        case .beginner:
            "1.circle"
        case .intermediate:
            "2.circle"
        case .advanced:
            "3.circle"
        case .expert:
            "graduationcap"
        }
    }
}
