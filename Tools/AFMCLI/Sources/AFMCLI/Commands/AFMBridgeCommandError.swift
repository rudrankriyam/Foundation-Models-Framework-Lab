import Foundation

enum AFMBridgeCommandError: LocalizedError, Sendable {
    case hostMissing(descriptorPath: String)
    case hostStopped(descriptorPath: String)
    case hostUnreachable(endpoint: String, reason: String)
    case invalidDescriptor(descriptorPath: String, reason: String)
    case invalidResponse(endpoint: String)
    case apiFailure(statusCode: Int, message: String, code: String?)
    case launchFailed(app: String, reason: String)
    case launchTimedOut(app: String, timeoutSeconds: Double, descriptorPath: String)

    var errorDescription: String? {
        switch self {
        case .hostMissing(let descriptorPath):
            "No Foundation Lab bridge host is registered at \(descriptorPath). "
                + "Run 'afm bridge prepare', then launch Foundation Lab and start Agent Bridge in Settings."
        case .hostStopped(let descriptorPath):
            "The Foundation Lab bridge descriptor at \(descriptorPath) is stale. "
                + "Launch or restart Foundation Lab; its persisted Agent Bridge setting will start the host."
        case .hostUnreachable(let endpoint, let reason):
            "Could not reach the Foundation Lab bridge at \(endpoint): \(reason) "
                + "Launch or restart Foundation Lab; its persisted Agent Bridge setting will start the host."
        case .invalidDescriptor(let descriptorPath, let reason):
            "The Foundation Lab bridge descriptor at \(descriptorPath) is invalid: \(reason) Restart Agent Bridge to replace it safely."
        case .invalidResponse(let endpoint):
            "Foundation Lab returned an invalid bridge response from \(endpoint). Update Foundation Lab and afm to compatible versions."
        case .apiFailure(let statusCode, let message, let code):
            "Foundation Lab bridge request failed with HTTP \(statusCode): \(message)\(code.map { " [\($0)]" } ?? "")"
        case .launchFailed(let app, let reason):
            "Could not launch Foundation Lab using '\(app)': \(reason)"
        case .launchTimedOut(let app, let timeoutSeconds, let descriptorPath):
            "Launched '\(app)', but no reachable Foundation Lab bridge appeared at \(descriptorPath) "
                + "within \(timeoutSeconds) seconds. Open Foundation Lab Settings and verify Agent Bridge is enabled."
        }
    }

    var permitsHostLaunchRecovery: Bool {
        switch self {
        case .hostMissing, .hostStopped, .hostUnreachable:
            true
        case .apiFailure(let statusCode, _, _):
            statusCode == 401
        case .invalidDescriptor, .invalidResponse, .launchFailed, .launchTimedOut:
            false
        }
    }
}
