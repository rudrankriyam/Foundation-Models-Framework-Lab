import Foundation

public enum AFMBridgeClientError: Error, Sendable, Equatable, LocalizedError {
    case unsupportedTransport
    case invalidConfiguration(field: String)
    case invalidResponse
    case responseTooLarge(maximumByteCount: Int)
    case transportFailure(code: URLError.Code)

    public var errorDescription: String? {
        switch self {
        case .unsupportedTransport:
            "The bridge client supports authenticated loopback TCP endpoints only."
        case .invalidConfiguration(let field):
            "The bridge client configuration field '\(field)' is invalid."
        case .invalidResponse:
            "The bridge returned a response that was not HTTP."
        case .responseTooLarge(let maximumByteCount):
            "The bridge response exceeded the \(maximumByteCount)-byte limit."
        case .transportFailure(let code):
            "The bridge request failed with URL error code \(code.rawValue)."
        }
    }
}
