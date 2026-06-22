import AFMServer
import Darwin
import Foundation
import Testing
@testable import AFMCLI

@Test("Bridge commands are discoverable and document headless inputs")
func bridgeHelp() throws {
    let root = try runAFM("--help")
    let bridge = try runAFM("bridge", "--help")
    let chat = try runAFM("bridge", "chat", "--help")

    #expect(root.status == 0)
    #expect(root.stdout.contains("AGENT BRIDGE COMMANDS"))
    #expect(root.stdout.contains("afm bridge"))
    for subcommand in ["prepare", "ensure", "status", "models", "chat"] {
        #expect(bridge.stdout.contains(subcommand))
    }
    for flag in ["--base", "--descriptor", "--prompt", "--model", "--max-tokens", "--temperature", "--top-p"] {
        #expect(chat.stdout.contains(flag))
    }
    #expect(bridge.stdout.contains("does not require a TTY"))
}

@Test("Bridge prepare creates private directories without a TTY")
func bridgePrepare() throws {
    try withBridgeTemporaryDirectory { parent in
        let base = parent.appending(path: ".afm")
        let result = try runAFM(
            "bridge", "prepare", "--base", base.path(),
            environment: ["AFM_FORCE_NON_TTY": "1"]
        )

        #expect(result.status == 0)
        let json = try parseJSONObject(result.stdout)
        #expect(json["status"] as? String == "prepared")
        #expect(json["baseDirectory"] as? String == base.path())
        #expect(json["bridgeDirectory"] as? String == base.appending(path: "bridge").path())
        #expect(json["descriptor"] as? String == base.appending(path: "bridge/connection.json").path())
        #expect(try bridgePermissions(at: base.path()) == 0o700)
        #expect(try bridgePermissions(at: base.appending(path: "bridge").path()) == 0o700)
    }
}

@Test("Bridge prepare rejects descriptor paths without changing their parent")
func bridgePrepareDescriptorIsReadOnly() throws {
    try withBridgeTemporaryDirectory { parent in
        #expect(Darwin.chmod(parent.path(), 0o755) == 0)
        let permissionsBefore = try bridgePermissions(at: parent.path())
        let descriptor = parent.appending(path: "connection.json")

        let result = try runAFM("bridge", "prepare", "--descriptor", descriptor.path())

        #expect(result.status == 64)
        #expect(result.stderr.contains("--descriptor is read-only"))
        #expect(try bridgePermissions(at: parent.path()) == permissionsBefore)
        #expect(!FileManager.default.fileExists(atPath: descriptor.path()))
    }
}

@Test("Bridge prepare refuses to chmod an existing base directory")
func bridgePrepareDoesNotRepairExistingBase() throws {
    try withBridgeTemporaryDirectory { parent in
        let base = parent.appending(path: "existing-base")
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: false)
        #expect(Darwin.chmod(base.path(), 0o755) == 0)

        let result = try runAFM("bridge", "prepare", "--base", base.path())

        #expect(result.status != 0)
        #expect(result.stderr.contains("mode 755; expected 700"))
        #expect(try bridgePermissions(at: base.path()) == 0o755)
        #expect(!FileManager.default.fileExists(atPath: base.appending(path: "bridge").path()))
    }
}

@Test("Bridge reports missing and stale hosts with launch guidance")
func bridgeMissingAndStaleHostErrors() throws {
    try withBridgeTemporaryDirectory { parent in
        let descriptor = parent.appending(path: "connection.json")
        let missing = try runAFM("bridge", "status", "--descriptor", descriptor.path())
        #expect(missing.status != 0)
        #expect(missing.stderr.contains("No Foundation Lab bridge host"))
        #expect(missing.stderr.contains("launch Foundation Lab"))

        let token = String(repeating: "s", count: 43)
        try writeBridgeDescriptor(
            at: descriptor,
            port: 19_760,
            token: token,
            processIdentifier: Int32.max
        )
        let stale = try runAFM("bridge", "status", "--descriptor", descriptor.path())
        #expect(stale.status != 0)
        #expect(stale.stderr.contains("is stale"))
        #expect(stale.stderr.contains("Launch or restart Foundation Lab"))
        #expect(!stale.stdout.contains(token))
        #expect(!stale.stderr.contains(token))
    }
}

@Test("Bridge status, models, and chat work headlessly without exposing credentials")
func bridgeHeadlessRoundTrip() async throws {
    let token = "never-print-this-bridge-token-value-1234567"
    #expect(token.utf8.count == 43)
    let probe = BridgeGeneratorProbe()
    let server = try AFMHTTPServer(
        configuration: .init(
            endpoint: .tcp(host: "127.0.0.1", port: 0),
            security: .init(bearerToken: token)
        ),
        catalog: AFMStaticModelCatalog(models: [
            .init(id: "system", isAvailable: true),
            .init(id: "pcc", isAvailable: true)
        ]),
        generator: BridgeTestGenerator(probe: probe)
    )
    let address = try await server.start()
    guard case .tcp(_, let port) = address else {
        try await server.stop()
        Issue.record("Expected a TCP bridge test server")
        return
    }

    do {
        let parent = try makeBridgeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: parent) }
        let descriptor = parent.appending(path: "connection.json")
        try writeBridgeDescriptor(
            at: descriptor,
            port: port,
            token: token,
            processIdentifier: getpid()
        )
        let environment = ["AFM_FORCE_NON_TTY": "1"]
        let results = try runHeadlessBridgeCommands(descriptor: descriptor, environment: environment)
        try await verifyHeadlessBridgeResults(results, probe: probe, token: token)
        try await server.stop()
    } catch {
        try? await server.stop()
        throw error
    }
}

private struct BridgeHeadlessCommandResults {
    let status: CommandResult
    let ensure: CommandResult
    let models: CommandResult
    let chat: CommandResult

    var output: [String] {
        [
            status.stdout, status.stderr, ensure.stdout, ensure.stderr,
            models.stdout, models.stderr, chat.stdout, chat.stderr
        ]
    }
}

private func runHeadlessBridgeCommands(
    descriptor: URL,
    environment: [String: String]
) throws -> BridgeHeadlessCommandResults {
    let status = try runAFM(
        ["bridge", "status", "--descriptor", descriptor.path()],
        environment: environment
    )
    let ensure = try runAFM(
        [
            "bridge", "ensure", "--descriptor", descriptor.path(),
            "--app", "/definitely/not/a/Foundation Lab.app"
        ],
        environment: environment
    )
    let models = try runAFM(
        ["bridge", "models", "--descriptor", descriptor.path()],
        environment: environment
    )
    let chat = try runAFM(
        [
            "bridge", "chat", "--descriptor", descriptor.path(),
            "--model", "pcc", "--max-tokens", "128", "--temperature", "0.25",
            "--top-p", "0.8", "--prompt", "Explain no-TTY PCC."
        ],
        environment: environment
    )
    return BridgeHeadlessCommandResults(status: status, ensure: ensure, models: models, chat: chat)
}

private func verifyHeadlessBridgeResults(
    _ results: BridgeHeadlessCommandResults,
    probe: BridgeGeneratorProbe,
    token: String
) async throws {
    #expect(results.status.status == 0)
    let statusJSON = try parseJSONObject(results.status.stdout)
    #expect(statusJSON["status"] as? String == "running")
    let statusModels = try #require(statusJSON["models"] as? [[String: Any]])
    #expect(Set(statusModels.compactMap { $0["name"] as? String }) == ["system", "pcc"])

    #expect(results.ensure.status == 0)
    let ensureJSON = try parseJSONObject(results.ensure.stdout)
    #expect(ensureJSON["status"] as? String == "already_running")

    #expect(results.models.status == 0)
    let modelsJSON = try parseJSONObject(results.models.stdout)
    let modelEntries = try #require(modelsJSON["models"] as? [[String: Any]])
    #expect(Set(modelEntries.compactMap { $0["id"] as? String }) == ["system", "pcc"])

    #expect(results.chat.status == 0)
    let chatJSON = try parseJSONObject(results.chat.stdout)
    #expect(chatJSON["model"] as? String == "pcc")
    #expect(chatJSON["response"] as? String == "Headless bridge response")
    let usage = try #require(chatJSON["tokenUsage"] as? [String: Any])
    #expect(usage["measurement"] as? String == "observed")
    #expect(usage["totalTokenCount"] as? Int == 15)

    let request = try #require(await probe.lastRequest())
    #expect(request.model == "pcc")
    #expect(request.maximumCompletionTokens == 128)
    #expect(request.temperature == 0.25)
    #expect(request.topP == 0.8)
    for output in results.output {
        #expect(!output.contains(token))
    }
}

@Test("Bridge ensure dry-run does not require or launch an app")
func bridgeEnsureDryRun() throws {
    try withBridgeTemporaryDirectory { parent in
        let descriptor = parent.appending(path: "missing.json")
        let app = parent.appending(path: "Never Launch This.app")
        let result = try runAFM(
            "bridge", "ensure", "--descriptor", descriptor.path(),
            "--app", app.path(), "--timeout", "0.1", "--dry-run",
            environment: ["AFM_FORCE_NON_TTY": "1"]
        )

        #expect(result.status == 0)
        let json = try parseJSONObject(result.stdout)
        #expect(json["status"] as? String == "dry_run")
        #expect(json["application"] as? String == app.path())
        #expect(!FileManager.default.fileExists(atPath: app.path()))
    }
}

@Test("Bridge requests retry rotated descriptors only when explicitly allowed")
func bridgeDescriptorRotationRetryPolicy() async throws {
    let parent = try makeBridgeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: parent) }
    let descriptor = parent.appending(path: "connection.json")
    let paths = ResolvedBridgePaths(
        baseDirectory: nil,
        bridgeDirectory: parent.path(),
        descriptorPath: descriptor.path(),
        descriptorFileName: descriptor.lastPathComponent
    )
    let launchIdentifier = UUID()
    let token = String(repeating: "r", count: 43)
    try writeBridgeDescriptor(
        at: descriptor,
        port: 19_760,
        token: token,
        processIdentifier: getpid(),
        launchIdentifier: launchIdentifier
    )

    var retriedAttempts = 0
    let retried: (host: AFMBridgeCommandConnection, response: Int) = try await performBridgeRequest(
        paths: paths
    ) { _ in
        retriedAttempts += 1
        if retriedAttempts == 1 {
            try writeBridgeDescriptor(
                at: descriptor,
                port: 19_761,
                token: token,
                processIdentifier: getpid(),
                launchIdentifier: launchIdentifier
            )
            throw BridgeOperationTestError.expectedFailure
        }
        return 42
    }
    #expect(retried.response == 42)
    #expect(retriedAttempts == 2)
    #expect(retried.host.descriptor.endpoint == .loopbackTCP(host: "127.0.0.1", port: 19_761))
    #expect(retried.host.descriptor.launchIdentifier == launchIdentifier)

    var nonRetryingAttempts = 0
    await #expect(throws: BridgeOperationTestError.expectedFailure) {
        let _: (host: AFMBridgeCommandConnection, response: Int) = try await performBridgeRequest(
            paths: paths,
            retryAfterDescriptorRotation: false
        ) { _ in
            nonRetryingAttempts += 1
            try writeBridgeDescriptor(
                at: descriptor,
                port: 19_762,
                token: String(repeating: "t", count: 43),
                processIdentifier: getpid()
            )
            throw BridgeOperationTestError.expectedFailure
        }
    }
    #expect(nonRetryingAttempts == 1)
}

@Test("Bridge polling clamps its last sleep and checks the deadline")
func bridgePollingFinalDeadlineCheck() async throws {
    let clock = BridgePollingTestClock()
    let deadline = clock.now.advanced(by: .milliseconds(250))
    var attempts = 0

    let result: Int? = try await pollForBridge(
        clock: clock,
        deadline: deadline,
        interval: .milliseconds(100)
    ) {
        attempts += 1
        return attempts == 4 ? 42 : nil
    }

    #expect(result == 42)
    #expect(attempts == 4)
    #expect(clock.now == deadline)
    #expect(clock.recordedSleepDeadlines().last == deadline)
    #expect(clock.recordedSleepDeadlines().allSatisfy { $0 <= deadline })
}

@Test("Bridge descriptor rotation never retries a cancelled operation")
func bridgeDescriptorRotationCancellation() async throws {
    let parent = try makeBridgeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: parent) }
    let descriptor = parent.appending(path: "connection.json")
    let paths = ResolvedBridgePaths(
        baseDirectory: nil,
        bridgeDirectory: parent.path(),
        descriptorPath: descriptor.path(),
        descriptorFileName: descriptor.lastPathComponent
    )
    try writeBridgeDescriptor(
        at: descriptor,
        port: 19_760,
        token: String(repeating: "c", count: 43),
        processIdentifier: getpid()
    )

    var attemptedLaunchIdentifiers: [UUID] = []
    do {
        let _: (host: AFMBridgeCommandConnection, response: Int) = try await performBridgeRequest(
            paths: paths
        ) { host in
            attemptedLaunchIdentifiers.append(host.descriptor.launchIdentifier)
            try writeBridgeDescriptor(
                at: descriptor,
                port: 19_761,
                token: String(repeating: "d", count: 43),
                processIdentifier: getpid()
            )
            throw CancellationError()
        }
        Issue.record("Expected cancellation")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("Expected CancellationError, got \(error)")
    }

    #expect(attemptedLaunchIdentifiers.count == 1)
    let attemptedLaunchIdentifier = try #require(attemptedLaunchIdentifiers.first)
    let rotatedDescriptor = try paths.readDescriptor()
    #expect(rotatedDescriptor.launchIdentifier != attemptedLaunchIdentifier)
}

@Test("Bridge command connections preserve request cancellation")
func bridgeCommandConnectionCancellation() async throws {
    let token = String(repeating: "c", count: 43)
    let probe = BridgeCancellationProbe()
    let server = try AFMHTTPServer(
        configuration: .init(
            endpoint: .tcp(host: "127.0.0.1", port: 0),
            security: .init(bearerToken: token)
        ),
        catalog: AFMStaticModelCatalog(models: [.init(id: "system", isAvailable: true)]),
        generator: BridgeCancellationGenerator(probe: probe)
    )
    let address = try await server.start()
    guard case .tcp(_, let port) = address else {
        try await server.stop()
        Issue.record("Expected a TCP bridge test server")
        return
    }

    let parent = try makeBridgeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: parent) }
    let descriptor = parent.appending(path: "connection.json")
    try writeBridgeDescriptor(at: descriptor, port: port, token: token, processIdentifier: getpid())
    let paths = ResolvedBridgePaths(
        baseDirectory: nil,
        bridgeDirectory: parent.path(),
        descriptorPath: descriptor.path(),
        descriptorFileName: descriptor.lastPathComponent
    )
    let connection = try AFMBridgeCommandConnection.connect(paths: paths)
    let body = Data(#"{"model":"system","messages":[{"role":"user","content":"Wait"}]}"#.utf8)
    let request = Task { try await connection.chat(body: body) }
    await probe.waitUntilStarted()
    request.cancel()

    do {
        _ = try await request.value
        Issue.record("Expected cancellation")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("Expected CancellationError, got \(error)")
    }
    try await server.stop()
}

private actor BridgeGeneratorProbe {
    private var request: AFMChatGenerationRequest?

    func capture(_ request: AFMChatGenerationRequest) {
        self.request = request
    }

    func lastRequest() -> AFMChatGenerationRequest? {
        request
    }
}

private actor BridgeCancellationProbe {
    private var started = false

    func markStarted() {
        started = true
    }

    func waitUntilStarted() async {
        while !started {
            await Task.yield()
        }
    }
}

private struct BridgeTestGenerator: AFMChatCompletionGenerating {
    let probe: BridgeGeneratorProbe

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        await probe.capture(request)
        return .init(
            content: "Headless bridge response",
            usage: .init(
                input: .init(totalTokenCount: 10, cachedTokenCount: 2),
                output: .init(totalTokenCount: 5, reasoningTokenCount: 1),
                measurement: .observed,
                scope: .response
            )
        )
    }
}

private struct BridgeCancellationGenerator: AFMChatCompletionGenerating {
    let probe: BridgeCancellationProbe

    func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        await probe.markStarted()
        try await ContinuousClock().sleep(for: .seconds(30))
        return .init(
            content: "Unexpected",
            usage: .init(inputTokenCount: 1, measurement: .estimated, scope: .response)
        )
    }
}

private enum BridgeOperationTestError: Error {
    case expectedFailure
}

private enum BridgeTestError: Error {
    case posix(String, CInt)
}

private final class BridgePollingTestClock: Clock, @unchecked Sendable {
    struct Instant: InstantProtocol {
        typealias Duration = Swift.Duration

        let offset: Duration

        func advanced(by duration: Duration) -> Self {
            Self(offset: offset + duration)
        }

        func duration(to other: Self) -> Duration {
            other.offset - offset
        }

        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }

    typealias Duration = Swift.Duration

    private let lock = NSLock()
    private var current = Instant(offset: .zero)
    private var sleepDeadlines: [Instant] = []

    var now: Instant {
        lock.withLock { current }
    }

    var minimumResolution: Duration { .nanoseconds(1) }

    func sleep(until deadline: Instant, tolerance: Duration?) async throws {
        try Task.checkCancellation()
        lock.withLock {
            sleepDeadlines.append(deadline)
            if current < deadline {
                current = deadline
            }
        }
    }

    func recordedSleepDeadlines() -> [Instant] {
        lock.withLock { sleepDeadlines }
    }
}

private func withBridgeTemporaryDirectory<Result>(
    _ operation: (URL) throws -> Result
) throws -> Result {
    let directory = try makeBridgeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    return try operation(directory)
}

private func makeBridgeTemporaryDirectory() throws -> URL {
    let directory = URL(fileURLWithPath: "/tmp/afm-cli-bridge-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
    guard Darwin.chmod(directory.path(), 0o700) == 0 else {
        throw BridgeTestError.posix("secure temporary directory", errno)
    }
    return directory
}

private func bridgePermissions(at path: String) throws -> mode_t {
    var status = stat()
    guard Darwin.lstat(path, &status) == 0 else {
        throw BridgeTestError.posix("inspect \(path)", errno)
    }
    return status.st_mode & 0o777
}

private func writeBridgeDescriptor(
    at url: URL,
    port: Int,
    token: String,
    processIdentifier: Int32,
    launchIdentifier: UUID = UUID()
) throws {
    let object: [String: Any] = [
        "version": 1,
        "endpoint": ["loopbackTCP": ["host": "127.0.0.1", "port": port]],
        "bearerToken": token,
        "processIdentifier": processIdentifier,
        "launchIdentifier": launchIdentifier.uuidString,
        "modelIdentifiers": ["system", "pcc"],
        "startedAt": 0
    ]
    let data = try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    try data.write(to: url, options: .atomic)
    guard Darwin.chmod(url.path(), 0o600) == 0 else {
        throw BridgeTestError.posix("secure descriptor", errno)
    }
}
