import ArgumentParser
import Foundation

struct BridgeEnsureCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ensure",
        abstract: "Launch Foundation Lab when needed and wait for a reachable bridge.",
        aliases: ["launch"]
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var connection: BridgeConnectionOptions

    @Option(
        name: .long,
        help: "Foundation Lab application name or .app path. Defaults to Foundation Lab."
    )
    var app: String?

    @Option(name: .customLong("timeout"), help: "Maximum seconds to wait for the bridge. Defaults to 20.")
    var timeoutSeconds: Double = 20

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        try await executeBridgeCommand(output: output) {
            try await execute(output: output)
        }
    }

    private func execute(output: CLIOutputOptions) async throws {
        let paths = try connection.resolve()
        let application = try resolvedApplication()
        guard timeoutSeconds.isFinite, timeoutSeconds > 0, timeoutSeconds <= 300 else {
            throw ValidationError("--timeout must be greater than 0 and at most 300 seconds.")
        }

        if options.dryRun {
            try emitBridgeEnsureDryRun(
                application: application,
                timeoutSeconds: timeoutSeconds,
                paths: paths,
                output: output
            )
            return
        }

        if let existing = try await reachableBridge(paths: paths) {
            try emitBridgeEnsureResult(
                status: "already_running",
                host: existing.host,
                health: existing.response,
                output: output
            )
            return
        }

        try launchFoundationLab(application)
        try await waitForBridge(
            paths: paths,
            application: application,
            timeoutSeconds: timeoutSeconds,
            output: output
        )
    }

    private func resolvedApplication() throws -> String {
        guard let app else { return "Foundation Lab" }
        return try validatedNonEmpty(app, optionName: "--app")
    }
}

private func reachableBridge(
    paths: ResolvedBridgePaths
) async throws -> (host: AFMBridgeCommandConnection, response: AFMBridgeHealthResponse)? {
    do {
        return try await performBridgeRequest(
            paths: paths,
            operation: { try await $0.health() }
        )
    } catch let error as AFMBridgeCommandError {
        guard error.permitsHostLaunchRecovery else { throw error }
        return nil
    }
}

private func waitForBridge(
    paths: ResolvedBridgePaths,
    application: String,
    timeoutSeconds: Double,
    output: CLIOutputOptions
) async throws {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: .seconds(timeoutSeconds))
    if let launched = try await pollForBridge(
        clock: clock,
        deadline: deadline,
        interval: .milliseconds(200),
        operation: { try await reachableBridge(paths: paths) }
    ) {
        try emitBridgeEnsureResult(
            status: "launched",
            host: launched.host,
            health: launched.response,
            output: output
        )
        return
    }

    throw AFMBridgeCommandError.launchTimedOut(
        app: application,
        timeoutSeconds: timeoutSeconds,
        descriptorPath: paths.descriptorPath
    )
}

func pollForBridge<ClockType: Clock, Response>(
    clock: ClockType,
    deadline: ClockType.Instant,
    interval: ClockType.Duration,
    operation: () async throws -> Response?
) async throws -> Response? {
    while true {
        if let response = try await operation() {
            return response
        }
        let now = clock.now
        guard now < deadline else { return nil }
        let nextPoll = min(now.advanced(by: interval), deadline)
        try await clock.sleep(until: nextPoll, tolerance: nil)
    }
}

private func emitBridgeEnsureDryRun(
    application: String,
    timeoutSeconds: Double,
    paths: ResolvedBridgePaths,
    output: CLIOutputOptions
) throws {
    let payload = BridgeEnsureDryRunPayload(
        application: application,
        timeoutSeconds: timeoutSeconds,
        descriptor: paths.descriptorPath
    )
    try CLIOutput.emit(
        payload: payload,
        human: "[dry-run] afm bridge ensure \(application)",
        options: output
    )
}

private struct BridgeEnsureDryRunPayload: Encodable {
    let status = "dry_run"
    let command = "bridge ensure"
    let application: String
    let timeoutSeconds: Double
    let descriptor: String
}

private struct BridgeEnsurePayload: Encodable {
    let status: String
    let command = "bridge ensure"
    let endpoint: String
    let processIdentifier: Int32
    let launchIdentifier: UUID
    let models: [AFMBridgeHealthResponse.Model]
}

private func launchFoundationLab(_ application: String) throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    let expandedApplication = expandedPathString(application)
    if expandedApplication.contains("/") || expandedApplication.hasSuffix(".app") {
        process.arguments = ["-gj", expandedApplication]
    } else {
        process.arguments = ["-gj", "-a", application]
    }
    process.standardInput = FileHandle.nullDevice
    let stderr = Pipe()
    process.standardOutput = FileHandle.nullDevice
    process.standardError = stderr

    do {
        try process.run()
        process.waitUntilExit()
    } catch {
        throw AFMBridgeCommandError.launchFailed(app: application, reason: error.localizedDescription)
    }

    guard process.terminationStatus == 0 else {
        let data = stderr.fileHandleForReading.readDataToEndOfFile()
        let message = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        throw AFMBridgeCommandError.launchFailed(
            app: application,
            reason: message.flatMap { $0.isEmpty ? nil : $0 } ?? "open exited with status \(process.terminationStatus)."
        )
    }
}

private func emitBridgeEnsureResult(
    status: String,
    host: AFMBridgeCommandConnection,
    health: AFMBridgeHealthResponse,
    output: CLIOutputOptions
) throws {
    let payload = BridgeEnsurePayload(
        status: status,
        endpoint: host.endpointDescription,
        processIdentifier: host.descriptor.processIdentifier,
        launchIdentifier: host.descriptor.launchIdentifier,
        models: health.models
    )
    let action = status == "launched" ? "launched and is reachable" : "is already reachable"
    try CLIOutput.emit(
        payload: payload,
        human: "Foundation Lab \(action).\nEndpoint: \(host.endpointDescription)",
        options: output
    )
}
