import Foundation
import Security

public enum AFMBridgeTokenError: Error, Sendable, Equatable, LocalizedError {
    case randomGenerationFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .randomGenerationFailed(let status):
            "Could not generate a secure bridge token (Security status \(status))."
        }
    }
}
