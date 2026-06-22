import ArgumentParser

struct BridgeModelsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "models",
        abstract: "List models exposed by the signed Foundation Lab bridge host."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var connection: BridgeConnectionOptions

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        try await executeBridgeCommand(output: output) {
            let paths = try connection.resolve()
            if options.dryRun {
                try CLIOutput.emit(
                    payload: BridgeConnectionDryRunPayload(command: "bridge models", paths: paths),
                    human: "[dry-run] afm bridge models \(paths.descriptorPath)",
                    options: output
                )
                return
            }

            let result = try await performBridgeRequest(paths: paths) { try await $0.models() }
            let lines = result.response.data.map { model in
                options.verbose ? "\(model.id)\n  Owner: \(model.owner)" : model.id
            }
            try CLIOutput.emit(
                payload: BridgeModelsPayload(host: result.host, response: result.response),
                human: lines.joined(separator: "\n"),
                options: output
            )
        }
    }
}

private struct BridgeModelsPayload: Encodable {
    let command = "bridge models"
    let endpoint: String
    let object: String
    let models: [AFMBridgeModelsResponse.Model]

    init(host: AFMBridgeCommandConnection, response: AFMBridgeModelsResponse) {
        endpoint = host.endpointDescription
        object = response.object
        models = response.data
    }
}
