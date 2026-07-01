import ArgumentParser
import Foundation
import FoundationModelsKit

struct QuotaUsageCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "quota-usage",
        abstract: "Inspect the current Private Cloud Compute quota state."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var selection: ModelSelectionOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: RuntimeDryRunPayload(
                    command: "quota-usage",
                    model: selection.model?.rawValue
                ),
                human: "[dry-run] afm quota-usage\(modelSuffix)",
                options: resolvedOutput
            )
            return
        }

        let results = FoundationModelQuotaUsageInspectionUseCase().execute(runtimes: selection.runtimes)
        let payload = QuotaUsagePayload(models: results.map(QuotaUsagePayload.Model.init))
        let human = results.map(quotaDescription).joined(separator: "\n")
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }

    private var modelSuffix: String {
        selection.model.map { " --model \($0.rawValue)" } ?? ""
    }
}

private struct QuotaUsagePayload: Encodable {
    struct Model: Encodable {
        let id: String
        let runtime: FoundationModelRuntime
        let status: FoundationModelQuotaStatus
        let resetDate: Date?
        let canRequestLimitIncrease: Bool
        let unavailableReason: FoundationModelRuntimeUnavailableReason?

        init(_ result: FoundationModelQuotaUsage) {
            id = modelIdentifier(for: result.runtime)
            runtime = result.runtime
            status = result.status
            resetDate = result.resetDate
            canRequestLimitIncrease = result.canRequestLimitIncrease
            unavailableReason = result.unavailableReason
        }
    }

    let command = "quota-usage"
    let models: [Model]
}

private func quotaDescription(_ result: FoundationModelQuotaUsage) -> String {
    let name = modelDisplayName(for: result.runtime)
    switch result.status {
    case .notApplicable:
        return "\(name): not applicable (quota only applies to PCC)"
    case .unavailable:
        return "\(name): unavailable (\(runtimeReasonDescription(result.unavailableReason)))"
    case .belowLimit:
        return "\(name): available (below limit)"
    case .approachingLimit:
        return "\(name): available (approaching limit)"
    case .limitReached:
        return "\(name): limit reached\(resetDescription(result.resetDate))"
    case .unsupported:
        return "\(name): unsupported (\(runtimeReasonDescription(result.unavailableReason)))"
    }
}

private func resetDescription(_ date: Date?) -> String {
    date.map { "; resets \($0.formatted(date: .abbreviated, time: .shortened))" } ?? ""
}
