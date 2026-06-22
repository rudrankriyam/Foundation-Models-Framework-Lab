#if os(macOS)
import Foundation
import Security

nonisolated enum AgentBridgePrivateCloudAuthorization {
    private static let entitlement = "com.apple.developer.private-cloud-compute"

    static var isGranted: Bool {
        guard let task = SecTaskCreateFromSelf(nil) else { return false }
        let value = SecTaskCopyValueForEntitlement(
            task,
            entitlement as CFString,
            nil
        )
        return (value as? Bool) == true
    }
}
#endif
