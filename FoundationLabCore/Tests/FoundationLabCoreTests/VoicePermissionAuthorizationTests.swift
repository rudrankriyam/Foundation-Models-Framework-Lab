import Testing
import FoundationModelsKit
@testable import FoundationLabCore

@Suite("Voice permission authorization")
struct VoicePermissionAuthorizationTests {
    @Test("Only an undetermined status can request system access")
    func requestActionRequiresUndeterminedStatus() {
        #expect(VoicePermissionAuthorization.notDetermined.requestAction == .requestAccess)
        #expect(VoicePermissionAuthorization.denied.requestAction == .returnDenied)
        #expect(VoicePermissionAuthorization.authorized.requestAction == .returnAuthorized)
    }
}
