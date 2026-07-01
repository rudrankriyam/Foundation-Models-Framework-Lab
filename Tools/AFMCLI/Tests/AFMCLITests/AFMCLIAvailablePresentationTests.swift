import FoundationModelsKit
import Testing
@testable import AFMCLI

@Test("Available text distinguishes framework availability from process authorization")
func availableTextDistinguishesAvailabilityFromAuthorization() {
    let unavailable = FoundationModelRuntimeStatus(
        runtime: .privateCloudCompute,
        isAvailable: false,
        authorization: .granted,
        reason: .systemNotReady
    )
    let missingAuthorization = FoundationModelRuntimeStatus(
        runtime: .privateCloudCompute,
        isAvailable: true,
        authorization: .missing,
        reason: .missingEntitlement
    )
    let unknownAuthorization = FoundationModelRuntimeStatus(
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

@Test("Runtime commands expose truthful structured status")
func runtimeCommandsExposeStructuredStatus() throws {
    let available = try runAFM("available", "--output", "json")
    let quota = try runAFM("quota-usage", "--output", "json")

    #expect(available.status == 0)
    #expect(quota.status == 0)

    let availableJSON = try parseJSONObject(available.stdout)
    let availableModels = try #require(availableJSON["models"] as? [[String: Any]])
    #expect(availableModels.compactMap { $0["id"] as? String } == ["system", "pcc"])
    #expect(availableModels.allSatisfy { $0["isRunnableInCurrentProcess"] is Bool })

    let quotaJSON = try parseJSONObject(quota.stdout)
    let quotaModels = try #require(quotaJSON["models"] as? [[String: Any]])
    #expect(quotaModels.compactMap { $0["id"] as? String } == ["system", "pcc"])
    #expect(quotaModels.first?["status"] as? String == "notApplicable")
}
