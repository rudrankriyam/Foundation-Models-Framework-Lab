import Foundation

public protocol ModelRuntimeInspecting: Sendable {
    func status(for runtime: FoundationLabModelRuntime) -> ModelRuntimeStatusResult
    func quotaUsage(for runtime: FoundationLabModelRuntime) -> ModelQuotaUsageResult
}
