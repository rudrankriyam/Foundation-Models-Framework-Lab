import Foundation

public enum FoundationLabCoreError: LocalizedError, Sendable, Equatable {
    case invalidRequest(String)
    case unavailableCapability(String)
    case providerFailure(String)
    case unsupportedEnvironment(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return String(localized: "Invalid request: \(message)")
        case .unavailableCapability(let message):
            return String(localized: "Unavailable capability: \(message)")
        case .providerFailure(let message):
            return String(localized: "Provider failure: \(message)")
        case .unsupportedEnvironment(let message):
            return String(localized: "Unsupported environment: \(message)")
        }
    }
}
