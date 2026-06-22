import Foundation

public struct InspectModelRuntimeUseCase: Sendable {
    public static let descriptor = CapabilityDescriptor(
        id: "foundation-models.inspect-runtime",
        displayName: "Inspect Model Runtime",
        summary: "Reports availability for on-device and Private Cloud Compute models."
    )

    private let inspector: any ModelRuntimeInspecting

    public init(inspector: any ModelRuntimeInspecting = FoundationModelsRuntimeInspector()) {
        self.inspector = inspector
    }

    public func execute(
        runtimes: [FoundationLabModelRuntime] = FoundationLabModelRuntime.allCases
    ) -> [ModelRuntimeStatusResult] {
        runtimes.map(inspector.status(for:))
    }
}
