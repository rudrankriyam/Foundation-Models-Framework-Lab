import AFMServer
import ArgumentParser
import Foundation
import FoundationLabCore

struct ServeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "serve",
        abstract: "Serve local Foundation Models-compatible HTTP endpoints."
    )

    @OptionGroup var options: GlobalCommandOptions

    @Option(name: .long, help: "TCP host. Defaults to 127.0.0.1.")
    var host: String?

    @Option(name: .long, help: "TCP port. Defaults to 1976.")
    var port: Int?

    @Option(name: .long, help: "Listen on an absolute Unix-domain socket path instead of TCP.")
    var socket: String?

    @Flag(name: .customLong("allow-network"), help: "Allow a non-loopback TCP binding.")
    var allowNetwork = false

    @Option(
        name: .customLong("token"),
        help: "Require this bearer token. Prefer the AFM_SERVER_TOKEN environment variable."
    )
    var bearerToken: String?

    @Option(
        name: .customLong("allow-origin"),
        parsing: .upToNextOption,
        help: "Allow an exact Origin value. Repeat for multiple origins."
    )
    var allowedOrigins: [String] = []

    @Option(
        name: .customLong("max-concurrent-generations"),
        help: "Maximum in-flight model generations. Defaults to 1."
    )
    var maximumConcurrentGenerations = 1

    @Option(
        name: .customLong("model-timeout"),
        help: "Model generation timeout in seconds. Defaults to 120."
    )
    var modelTimeoutSeconds: Double = 120

    mutating func run() async throws {
        let output = try options.resolvedOutput()
        let serverConfiguration = try resolvedServerConfiguration()

        if options.dryRun {
            let payload = ServeDryRunPayload(configuration: serverConfiguration)
            try CLIOutput.emit(
                payload: payload,
                human: "[dry-run] afm serve \(payload.endpoint)",
                options: output
            )
            return
        }

        let availability = CheckModelAvailabilityUseCase().execute()
        let catalog = AFMStaticModelCatalog(
            models: [.init(id: "system", isAvailable: availability.isAvailable)]
        )
        let server = try AFMHTTPServer(configuration: serverConfiguration, catalog: catalog)
        let terminationSignal = AFMTerminationSignal()

        do {
            let address = try await server.start()
            try emitStartupMessage(
                address: address,
                configuration: serverConfiguration,
                output: output
            )
            try await waitForShutdown(server: server, terminationSignal: terminationSignal)
        } catch {
            try? await server.stop()
            throw error
        }
    }

    private func waitForShutdown(
        server: AFMHTTPServer,
        terminationSignal: AFMTerminationSignal
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await terminationSignal.wait()
            }
            group.addTask {
                try await server.waitUntilClosed()
            }

            _ = try await group.next()
            try await server.stop()
            group.cancelAll()
        }
    }

    private func resolvedServerConfiguration() throws -> AFMServerConfiguration {
        let endpoint: AFMServerEndpoint
        if let socket {
            guard host == nil, port == nil else {
                throw ValidationError("--socket cannot be combined with --host or --port")
            }
            guard !allowNetwork else {
                throw ValidationError("--allow-network is only valid with a TCP endpoint")
            }
            endpoint = .unixSocket(path: socket)
        } else {
            let resolvedPort = port ?? 1976
            guard (1...65_535).contains(resolvedPort) else {
                throw ValidationError("--port must be between 1 and 65535")
            }
            endpoint = .tcp(host: host ?? "127.0.0.1", port: resolvedPort)
        }

        let environmentToken = ProcessInfo.processInfo.environment["AFM_SERVER_TOKEN"]
            .flatMap { $0.isEmpty ? nil : $0 }
        let configuration = AFMServerConfiguration(
            endpoint: endpoint,
            security: .init(
                allowNetwork: allowNetwork,
                bearerToken: bearerToken ?? environmentToken,
                allowedOrigins: Set(allowedOrigins)
            ),
            generation: .init(
                maximumConcurrentGenerations: maximumConcurrentGenerations,
                timeoutSeconds: modelTimeoutSeconds
            )
        )
        do {
            return try configuration.validated()
        } catch {
            throw ValidationError(error.localizedDescription)
        }
    }

    private func emitStartupMessage(
        address: AFMServerBoundAddress,
        configuration: AFMServerConfiguration,
        output: CLIOutputOptions
    ) throws {
        let payload = ServeStartedPayload(address: address, configuration: configuration)
        var humanLines = ["afm serve listening on \(payload.endpoint)"]
        if configuration.security.bearerToken != nil {
            humanLines.append("Bearer authentication is enabled.")
        }
        try CLIOutput.emit(payload: payload, human: humanLines.joined(separator: "\n"), options: output)
        fflush(stdout)
        if payload.networkExposed, output.format == .text {
            fputs("Warning: requests travel over plaintext HTTP on the local network.\n", stderr)
        }
    }
}

private struct ServeDryRunPayload: Encodable {
    let status = "dry_run"
    let command = "serve"
    let endpoint: String
    let authenticationEnabled: Bool
    let allowedOrigins: [String]
    let maximumConcurrentGenerations: Int
    let modelTimeoutSeconds: Double

    init(configuration: AFMServerConfiguration) {
        switch configuration.endpoint {
        case .tcp(let host, let port):
            endpoint = AFMServerBoundAddress.tcp(host: host, port: port).description
        case .unixSocket(let path):
            endpoint = "unix://\(path)"
        }
        authenticationEnabled = configuration.security.bearerToken != nil
        allowedOrigins = configuration.security.allowedOrigins.sorted()
        maximumConcurrentGenerations = configuration.generation.maximumConcurrentGenerations
        modelTimeoutSeconds = configuration.generation.timeoutSeconds
    }
}

private struct ServeStartedPayload: Encodable {
    let status = "started"
    let command = "serve"
    let endpoint: String
    let transport: String
    let authenticationEnabled: Bool
    let allowedOrigins: [String]
    let networkExposed: Bool
    let maximumConcurrentGenerations: Int
    let modelTimeoutSeconds: Double

    init(address: AFMServerBoundAddress, configuration: AFMServerConfiguration) {
        switch address {
        case .tcp(let host, let port):
            let renderedHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
            endpoint = "http://\(renderedHost):\(port)"
            transport = "tcp"
        case .unixSocket(let path):
            endpoint = "unix://\(path)"
            transport = "unix"
        }
        authenticationEnabled = configuration.security.bearerToken != nil
        allowedOrigins = configuration.security.allowedOrigins.sorted()
        maximumConcurrentGenerations = configuration.generation.maximumConcurrentGenerations
        modelTimeoutSeconds = configuration.generation.timeoutSeconds
        if case .tcp(let host, _) = configuration.endpoint {
            let normalizedHost = host.lowercased()
            networkExposed = !normalizedHost.hasPrefix("127.")
                && normalizedHost != "localhost"
                && normalizedHost != "::1"
                && normalizedHost != "[::1]"
        } else {
            networkExposed = false
        }
    }
}
