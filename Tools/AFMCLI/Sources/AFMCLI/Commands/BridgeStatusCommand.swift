import ArgumentParser
import Foundation

struct BridgeStatusCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "status",
        abstract: "Verify that the signed Foundation Lab bridge host is reachable."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var connection: BridgeConnectionOptions

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        try await executeBridgeCommand(output: output) {
            let paths = try connection.resolve()
            if options.dryRun {
                try CLIOutput.emit(
                    payload: BridgeConnectionDryRunPayload(command: "bridge status", paths: paths),
                    human: "[dry-run] afm bridge status \(paths.descriptorPath)",
                    options: output
                )
                return
            }

            let result = try await performBridgeRequest(paths: paths) { try await $0.health() }
            var lines = [
                "Foundation Lab Agent Bridge",
                "Status: Running",
                "Endpoint: \(result.host.endpointDescription)",
                "Process: \(result.host.descriptor.processIdentifier)",
                "Models: \(result.response.models.map { modelLabel($0) }.joined(separator: ", "))"
            ]
            if options.verbose {
                lines.append("Launch: \(result.host.descriptor.launchIdentifier.uuidString)")
                lines.append("Started: \(bridgeISO8601String(result.host.descriptor.startedAt))")
            }
            try CLIOutput.emit(
                payload: BridgeStatusPayload(host: result.host, health: result.response),
                human: lines.joined(separator: "\n"),
                options: output
            )
        }
    }
}

private struct BridgeStatusPayload: Encodable {
    let status = "running"
    let command = "bridge status"
    let endpoint: String
    let processIdentifier: Int32
    let launchIdentifier: UUID
    let startedAt: String
    let models: [AFMBridgeHealthResponse.Model]

    init(host: AFMBridgeCommandConnection, health: AFMBridgeHealthResponse) {
        endpoint = host.endpointDescription
        processIdentifier = host.descriptor.processIdentifier
        launchIdentifier = host.descriptor.launchIdentifier
        startedAt = bridgeISO8601String(host.descriptor.startedAt)
        models = health.models
    }
}

private func modelLabel(_ model: AFMBridgeHealthResponse.Model) -> String {
    model.available ? model.name : "\(model.name) (unavailable)"
}

private func bridgeISO8601String(_ date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}
