import Foundation

public struct InspectModelQuotaUsageUseCase: Sendable {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.inspect-quota-usage",
        displayName: "Inspect Model Quota Usage",
        summary: "Reports Private Cloud Compute quota state without inventing numeric usage."
    )

    private let inspector: any ModelRuntimeInspecting

    public init(inspector: any ModelRuntimeInspecting = FoundationModelsRuntimeInspector()) {
        self.inspector = inspector
    }

    public func execute(
        runtimes: [FoundationLabModelRuntime] = FoundationLabModelRuntime.allCases
    ) -> [ModelQuotaUsageResult] {
        runtimes.map(inspector.quotaUsage(for:))
    }
}
