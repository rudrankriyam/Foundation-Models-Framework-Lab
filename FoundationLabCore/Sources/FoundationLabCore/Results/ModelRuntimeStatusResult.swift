import Foundation

public enum ModelRuntimeUnavailableReason: String, Sendable, Hashable, Codable {
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    case modelNotReady
    case systemNotReady
    case unsupportedOperatingSystem
    case unsupportedToolchain
    case missingEntitlement
    case unknown
}

public enum ModelRuntimeAuthorization: String, Sendable, Hashable, Codable {
    case notRequired
    case granted
    case missing
    case unknown
}

public struct ModelRuntimeStatusResult: CapabilityResult, Sendable, Hashable, Codable {
    public let runtime: FoundationLabModelRuntime
    public let isSupported: Bool
    public let isAvailable: Bool
    public let isRunnableInCurrentProcess: Bool
    public let authorization: ModelRuntimeAuthorization
    public let reason: ModelRuntimeUnavailableReason?
    public let metadata: CapabilityExecutionMetadata

    public init(
        runtime: FoundationLabModelRuntime,
        isSupported: Bool = true,
        isAvailable: Bool,
        authorization: ModelRuntimeAuthorization = .notRequired,
        reason: ModelRuntimeUnavailableReason? = nil,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.runtime = runtime
        self.isSupported = isSupported
        self.isAvailable = isAvailable
        let hasRequiredAuthorization = authorization == .granted
            || (runtime == .onDevice && authorization == .notRequired)
        self.isRunnableInCurrentProcess = isSupported
            && isAvailable
            && hasRequiredAuthorization
        self.authorization = authorization
        self.reason = reason
        self.metadata = metadata
    }
}
