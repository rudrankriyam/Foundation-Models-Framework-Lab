import Foundation
import Testing
@testable import FoundationLabCore

@Test("Runtime inspection preserves requested ordering")
func runtimeInspectionPreservesOrdering() {
    let useCase = InspectModelRuntimeUseCase(inspector: StubRuntimeInspector())

    let results = useCase.execute(runtimes: [.privateCloudCompute, .onDevice])

    #expect(results.map(\.runtime) == [.privateCloudCompute, .onDevice])
    #expect(results.map(\.isRunnableInCurrentProcess) == [false, true])
}

@Test("Quota inspection reports system quota as not applicable")
func quotaInspectionReportsSystemAsNotApplicable() {
    let useCase = InspectModelQuotaUsageUseCase(inspector: StubRuntimeInspector())

    let results = useCase.execute(runtimes: [.onDevice, .privateCloudCompute])

    #expect(results.map(\.status) == [.notApplicable, .approachingLimit])
}

@Test("Missing managed entitlement makes PCC non-runnable")
func missingEntitlementMakesPCCNonRunnable() {
    let result = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: .missing,
        reason: .missingEntitlement
    )

    #expect(result.isSupported)
    #expect(!result.isRunnableInCurrentProcess)
    #expect(result.authorization == .missing)
}

private struct StubRuntimeInspector: ModelRuntimeInspecting {
    func status(for runtime: FoundationLabModelRuntime) -> ModelRuntimeStatusResult {
        switch runtime {
        case .onDevice:
            return ModelRuntimeStatusResult(runtime: runtime, isAvailable: true)
        case .privateCloudCompute:
            return ModelRuntimeStatusResult(
                runtime: runtime,
                isAvailable: true,
                authorization: .missing,
                reason: .missingEntitlement
            )
        }
    }

    func quotaUsage(for runtime: FoundationLabModelRuntime) -> ModelQuotaUsageResult {
        switch runtime {
        case .onDevice:
            return ModelQuotaUsageResult(runtime: runtime, status: .notApplicable)
        case .privateCloudCompute:
            return ModelQuotaUsageResult(runtime: runtime, status: .approachingLimit)
        }
    }
}
