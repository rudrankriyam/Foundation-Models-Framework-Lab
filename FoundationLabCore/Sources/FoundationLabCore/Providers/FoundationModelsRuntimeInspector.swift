import Foundation
import FoundationModels

public struct FoundationModelsRuntimeInspector: ModelRuntimeInspecting {
    public init() {}

    public func status(for runtime: FoundationLabModelRuntime) -> ModelRuntimeStatusResult {
        switch runtime {
        case .onDevice:
            return onDeviceStatus()
        case .privateCloudCompute:
            return privateCloudStatus()
        }
    }

    public func quotaUsage(for runtime: FoundationLabModelRuntime) -> ModelQuotaUsageResult {
        switch runtime {
        case .onDevice:
            return ModelQuotaUsageResult(
                runtime: .onDevice,
                status: .notApplicable,
                metadata: metadata(for: .onDevice)
            )
        case .privateCloudCompute:
            return privateCloudQuotaUsage()
        }
    }

    private func onDeviceStatus() -> ModelRuntimeStatusResult {
        let availability = FoundationModelsModelAvailabilityChecker().currentAvailability()
        return ModelRuntimeStatusResult(
            runtime: .onDevice,
            isAvailable: availability.isAvailable,
            reason: availability.reason.map(Self.runtimeReason),
            metadata: metadata(for: .onDevice)
        )
    }

    private func privateCloudStatus() -> ModelRuntimeStatusResult {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            switch model.availability {
            case .available:
                let authorization = PrivateCloudComputeEntitlementChecker().authorization()
                return ModelRuntimeStatusResult(
                    runtime: .privateCloudCompute,
                    isAvailable: true,
                    authorization: authorization,
                    metadata: metadata(for: .privateCloudCompute)
                )
            case .unavailable(let reason):
                return ModelRuntimeStatusResult(
                    runtime: .privateCloudCompute,
                    isAvailable: false,
                    authorization: PrivateCloudComputeEntitlementChecker().authorization(),
                    reason: Self.runtimeReason(reason),
                    metadata: metadata(for: .privateCloudCompute)
                )
            }
        }

        return unsupportedPrivateCloudStatus(reason: .unsupportedOperatingSystem)
        #else
        return unsupportedPrivateCloudStatus(reason: .unsupportedToolchain)
        #endif
    }

    private func privateCloudQuotaUsage() -> ModelQuotaUsageResult {
        let status = privateCloudStatus()
        if let unavailableResult = privateCloudUnavailableQuotaResult(for: status) {
            return unavailableResult
        }

        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            return quotaResult(PrivateCloudComputeLanguageModel().quotaUsage)
        }
        #endif

        return ModelQuotaUsageResult(
            runtime: .privateCloudCompute,
            status: .unsupported,
            unavailableReason: .unsupportedToolchain,
            metadata: metadata(for: .privateCloudCompute)
        )
    }

    func privateCloudUnavailableQuotaResult(
        for status: ModelRuntimeStatusResult
    ) -> ModelQuotaUsageResult? {
        guard status.runtime == .privateCloudCompute,
              !status.isRunnableInCurrentProcess else { return nil }
        return ModelQuotaUsageResult(
            runtime: .privateCloudCompute,
            status: status.isSupported ? .unavailable : .unsupported,
            unavailableReason: status.reason ?? .unknown,
            metadata: metadata(for: .privateCloudCompute)
        )
    }

    private func unsupportedPrivateCloudStatus(
        reason: ModelRuntimeUnavailableReason
    ) -> ModelRuntimeStatusResult {
        ModelRuntimeStatusResult(
            runtime: .privateCloudCompute,
            isSupported: false,
            isAvailable: false,
            authorization: .unknown,
            reason: reason,
            metadata: metadata(for: .privateCloudCompute)
        )
    }

    private func metadata(for runtime: FoundationLabModelRuntime) -> CapabilityExecutionMetadata {
        CapabilityExecutionMetadata(
            provider: "Foundation Models",
            modelIdentifier: runtime == .onDevice ? "system" : "pcc"
        )
    }

    private static func runtimeReason(
        _ reason: ModelAvailabilityUnavailableReason
    ) -> ModelRuntimeUnavailableReason {
        switch reason {
        case .deviceNotEligible:
            return .deviceNotEligible
        case .appleIntelligenceNotEnabled:
            return .appleIntelligenceNotEnabled
        case .modelNotReady:
            return .modelNotReady
        case .unknown:
            return .unknown
        }
    }
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
private extension FoundationModelsRuntimeInspector {
    static func runtimeReason(
        _ reason: PrivateCloudComputeLanguageModel.Availability.UnavailableReason
    ) -> ModelRuntimeUnavailableReason {
        switch reason {
        case .deviceNotEligible:
            return .deviceNotEligible
        case .systemNotReady:
            return .systemNotReady
        @unknown default:
            return .unknown
        }
    }

    func quotaResult(
        _ usage: PrivateCloudComputeLanguageModel.QuotaUsage
    ) -> ModelQuotaUsageResult {
        let status: ModelQuotaStatus
        switch usage.status {
        case .belowLimit(let details):
            status = details.isApproachingLimit ? .approachingLimit : .belowLimit
        case .limitReached:
            status = .limitReached
        @unknown default:
            status = .unavailable
        }

        return ModelQuotaUsageResult(
            runtime: .privateCloudCompute,
            status: status,
            resetDate: usage.resetDate,
            canRequestLimitIncrease: usage.limitIncreaseSuggestion != nil,
            metadata: metadata(for: .privateCloudCompute)
        )
    }
}
#endif
