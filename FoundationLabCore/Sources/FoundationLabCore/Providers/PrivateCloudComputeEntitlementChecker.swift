import Foundation

#if os(macOS)
import Security
#endif

public struct PrivateCloudComputeEntitlementChecker: Sendable {
    public static let entitlement = "com.apple.developer.private-cloud-compute"

    public init() {}

    public func authorization() -> ModelRuntimeAuthorization {
        #if os(macOS)
        guard let task = SecTaskCreateFromSelf(nil) else {
            return .unknown
        }
        let value = SecTaskCopyValueForEntitlement(
            task,
            Self.entitlement as CFString,
            nil
        )
        return (value as? Bool) == true ? .granted : .missing
        #else
        return .unknown
        #endif
    }
}
