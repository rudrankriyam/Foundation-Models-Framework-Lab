import Foundation

public enum ModelQuotaStatus: String, Sendable, Hashable, Codable {
    case notApplicable
    case unavailable
    case belowLimit
    case approachingLimit
    case limitReached
    case unsupported
}

public struct ModelQuotaUsageResult: CapabilityResult, Sendable, Hashable, Codable {
    public let runtime: FoundationLabModelRuntime
    public let status: ModelQuotaStatus
    public let resetDate: Date?
    public let canRequestLimitIncrease: Bool
    public let unavailableReason: ModelRuntimeUnavailableReason?
    public let metadata: CapabilityExecutionMetadata

    public init(
        runtime: FoundationLabModelRuntime,
        status: ModelQuotaStatus,
        resetDate: Date? = nil,
        canRequestLimitIncrease: Bool = false,
        unavailableReason: ModelRuntimeUnavailableReason? = nil,
        metadata: CapabilityExecutionMetadata = CapabilityExecutionMetadata()
    ) {
        self.runtime = runtime
        self.status = status
        self.resetDate = resetDate
        self.canRequestLimitIncrease = canRequestLimitIncrease
        self.unavailableReason = unavailableReason
        self.metadata = metadata
    }
}
