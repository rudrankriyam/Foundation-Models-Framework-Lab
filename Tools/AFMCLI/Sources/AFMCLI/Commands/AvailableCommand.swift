import ArgumentParser
import Foundation
import FoundationModelsKit

struct AvailableCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "available",
        abstract: "Inspect on-device and Private Cloud Compute availability."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var selection: ModelSelectionOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: RuntimeDryRunPayload(
                    command: "available",
                    model: selection.model?.rawValue
                ),
                human: "[dry-run] afm available\(modelSuffix)",
                options: resolvedOutput
            )
            return
        }

        let results = FoundationModelRuntimeInspectionUseCase().execute(runtimes: selection.runtimes)
        let payload = AvailablePayload(models: results.map(AvailablePayload.Model.init))
        let human = results.map(availableDescription).joined(separator: "\n")
        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }

    private var modelSuffix: String {
        selection.model.map { " --model \($0.rawValue)" } ?? ""
    }
}

private struct AvailablePayload: Encodable {
    struct Model: Encodable {
        let id: String
        let runtime: FoundationModelRuntime
        let isSupported: Bool
        let isAvailable: Bool
        let isRunnableInCurrentProcess: Bool
        let authorization: FoundationModelRuntimeAuthorization
        let reason: FoundationModelRuntimeUnavailableReason?

        init(_ result: FoundationModelRuntimeStatus) {
            id = modelIdentifier(for: result.runtime)
            runtime = result.runtime
            isSupported = result.isSupported
            isAvailable = result.isAvailable
            isRunnableInCurrentProcess = result.isRunnableInCurrentProcess
            authorization = result.authorization
            reason = result.reason
        }
    }

    let command = "available"
    let models: [Model]
}

func availableDescription(_ result: FoundationModelRuntimeStatus) -> String {
    let name = modelDisplayName(for: result.runtime)
    if result.isRunnableInCurrentProcess {
        return "\(name): available"
    }
    if result.isAvailable {
        let authorization = runtimeAuthorizationDescription(result.authorization)
        return "\(name): available, but not runnable in this process (\(authorization))"
    }
    return "\(name): unavailable (\(runtimeReasonDescription(result.reason)))"
}
