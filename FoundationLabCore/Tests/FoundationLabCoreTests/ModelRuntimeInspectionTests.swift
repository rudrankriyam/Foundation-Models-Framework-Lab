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

@Test(
    "Unconfirmed managed entitlement makes PCC non-runnable",
    arguments: [
        (ModelRuntimeAuthorization.missing, ModelRuntimeUnavailableReason.missingEntitlement),
        (.unknown, .unknown),
        (.notRequired, .unknown)
    ]
)
func unconfirmedEntitlementMakesPCCNonRunnable(
    authorization: ModelRuntimeAuthorization,
    expectedReason: ModelRuntimeUnavailableReason
) {
    let result = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: authorization
    )

    #expect(result.isSupported)
    #expect(!result.isRunnableInCurrentProcess)
    #expect(result.authorization == authorization)
    #expect(result.reason == expectedReason)
}

@Test(
    "Skipped PCC quota preserves the authorization failure reason",
    arguments: [
        (ModelRuntimeAuthorization.missing, ModelRuntimeUnavailableReason.missingEntitlement),
        (.unknown, .unknown)
    ]
)
func skippedPCCQuotaPreservesAuthorizationReason(
    authorization: ModelRuntimeAuthorization,
    expectedReason: ModelRuntimeUnavailableReason
) throws {
    let runtimeStatus = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: false,
        authorization: authorization,
        reason: .systemNotReady
    )

    let result = try #require(
        FoundationModelsRuntimeInspector().privateCloudUnavailableQuotaResult(for: runtimeStatus)
    )

    #expect(result.status == .unavailable)
    #expect(result.unavailableReason == expectedReason)
}

@Test("PCC quota remains inspectable while authorized inference is unavailable")
func authorizedPCCQuotaIgnoresInferenceAvailability() {
    let runtimeStatus = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: false,
        authorization: .granted,
        reason: .systemNotReady
    )

    let result = FoundationModelsRuntimeInspector()
        .privateCloudUnavailableQuotaResult(for: runtimeStatus)

    #expect(result == nil)
}

@Test("PCC quota preserves unsupported runtime reasons")
func unsupportedPCCQuotaPreservesRuntimeReason() throws {
    let runtimeStatus = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isSupported: false,
        isAvailable: false,
        authorization: .unknown,
        reason: .unsupportedOperatingSystem
    )

    let result = try #require(
        FoundationModelsRuntimeInspector().privateCloudUnavailableQuotaResult(for: runtimeStatus)
    )

    #expect(result.status == .unsupported)
    #expect(result.unavailableReason == .unsupportedOperatingSystem)
}

@Test("Confirmed managed entitlement makes available PCC runnable")
func grantedEntitlementMakesPCCRunnable() {
    let result = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: .granted
    )

    #expect(result.isRunnableInCurrentProcess)
}

@Test("On-device runtime is runnable without managed PCC authorization")
func onDeviceRuntimeDoesNotRequirePCCAuthorization() {
    let result = ModelRuntimeStatusResult(
        runtime: .onDevice,
        isAvailable: true
    )

    #expect(result.isRunnableInCurrentProcess)
    #expect(result.authorization == .notRequired)
}

@Test("Unsupported or unavailable runtimes remain non-runnable")
func unsupportedOrUnavailableRuntimesRemainNonRunnable() {
    let unavailable = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: false,
        authorization: .granted
    )
    let unsupported = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isSupported: false,
        isAvailable: true,
        authorization: .granted
    )

    #expect(!unavailable.isRunnableInCurrentProcess)
    #expect(!unsupported.isRunnableInCurrentProcess)
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
