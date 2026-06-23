/// The platform-independent authorization states used by the voice permission flow.
public enum VoicePermissionAuthorization: Sendable, Equatable {
    case notDetermined
    case denied
    case authorized

    /// The only safe next step for a user-initiated permission request.
    public var requestAction: RequestAction {
        switch self {
        case .notDetermined:
            .requestAccess
        case .denied:
            .returnDenied
        case .authorized:
            .returnAuthorized
        }
    }

    public enum RequestAction: Sendable, Equatable {
        case requestAccess
        case returnDenied
        case returnAuthorized
    }
}
