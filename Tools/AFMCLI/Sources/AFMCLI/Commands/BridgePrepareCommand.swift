import ArgumentParser

struct BridgePrepareCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "prepare",
        abstract: "Create the private directory used to discover Foundation Lab."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var connection: BridgeConnectionOptions

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        try await executeBridgeCommand(output: output) {
            let paths = try connection.resolveForPrepare()
            let payload = BridgePreparePayload(
                status: options.dryRun ? "dry_run" : "prepared",
                paths: paths
            )

            if options.dryRun {
                try CLIOutput.emit(
                    payload: payload,
                    human: "[dry-run] afm bridge prepare \(paths.bridgeDirectory)",
                    options: output
                )
                return
            }

            try paths.prepare()
            let lines = [
                "Prepared the private Agent Bridge directory at \(paths.bridgeDirectory).",
                "In Foundation Lab Settings, choose \(paths.baseDirectory ?? paths.bridgeDirectory) and start Agent Bridge.",
                "Descriptor: \(paths.descriptorPath)"
            ]
            try CLIOutput.emit(payload: payload, human: lines.joined(separator: "\n"), options: output)
        }
    }
}

private struct BridgePreparePayload: Encodable {
    let status: String
    let command = "bridge prepare"
    let baseDirectory: String?
    let bridgeDirectory: String
    let descriptor: String

    init(status: String, paths: ResolvedBridgePaths) {
        self.status = status
        baseDirectory = paths.baseDirectory
        bridgeDirectory = paths.bridgeDirectory
        descriptor = paths.descriptorPath
    }
}
