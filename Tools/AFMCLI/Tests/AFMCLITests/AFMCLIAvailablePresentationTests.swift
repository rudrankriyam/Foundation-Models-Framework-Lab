import FoundationLabCore
import Testing
@testable import AFMCLI

@Test("Available text distinguishes framework availability from process authorization")
func availableTextDistinguishesAvailabilityFromAuthorization() {
    let unavailable = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: false,
        authorization: .granted,
        reason: .systemNotReady
    )
    let missingAuthorization = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: .missing,
        reason: .missingEntitlement
    )
    let unknownAuthorization = ModelRuntimeStatusResult(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: .unknown
    )

    #expect(availableDescription(unavailable) == "PCC: unavailable (PCC is not ready)")
    #expect(
        availableDescription(missingAuthorization)
            == "PCC: available, but not runnable in this process "
                + "(current process lacks the managed PCC entitlement)"
    )
    #expect(
        availableDescription(unknownAuthorization)
            == "PCC: available, but not runnable in this process "
                + "(current-process authorization is unknown)"
    )
}
