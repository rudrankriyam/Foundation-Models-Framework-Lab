#if os(macOS)
import AFMServer
import Foundation
import Observation

@MainActor
@Observable
final class AgentBridgeController {
    enum Status: Sendable, Equatable {
        case notConfigured
        case off
        case starting
        case running
        case stopping
        case failed
    }

    enum Error: LocalizedError {
        case noAvailableModels
        case secureTokenUnavailable(String)
        case unexpectedEndpoint
        case emptySelection

        var errorDescription: String? {
            switch self {
            case .noAvailableModels:
                String(localized: "No Foundation Models runtime is ready on this Mac.")
            case .secureTokenUnavailable(let reason):
                String(localized: "The bridge could not create its launch token: \(reason)")
            case .unexpectedEndpoint:
                String(localized: "The bridge server did not bind its requested loopback endpoint.")
            case .emptySelection:
                String(localized: "No bridge folder was selected.")
            }
        }
    }

    var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            preferenceDefaults.set(isEnabled, forKey: Self.enabledPreferenceKey)
            guard hasActivated else { return }
            scheduleReconciliation()
        }
    }

    private(set) var status: Status
    private(set) var baseDirectoryPath: String?
    private(set) var descriptorPath: String?
    private(set) var errorMessage: String?

    @ObservationIgnored private let bookmarkStore: AgentBridgeBookmarkStore
    @ObservationIgnored private let preferenceDefaults: UserDefaults
    @ObservationIgnored private let bearerToken: String?
    @ObservationIgnored private let tokenErrorDescription: String?
    @ObservationIgnored private let launchIdentifier = UUID()
    @ObservationIgnored private var server: AFMHTTPServer?
    @ObservationIgnored private var descriptorLease: AFMBridgeDescriptorLease?
    @ObservationIgnored private var activeBaseDirectory: URL?
    @ObservationIgnored private var protectsProcessLifetime = false
    @ObservationIgnored private var hasActivated = false
    @ObservationIgnored private var reconciliationTask: Task<Void, Never>?
    @ObservationIgnored private var cleanupFailureContext: String?

    private static let enabledPreferenceKey = "agentBridge.isEnabled.v1"
    private static let bridgeDirectoryName = "bridge"
    private static let loopbackHost = "127.0.0.1"
    private static let terminationReason = "Foundation Lab agent bridge is serving local requests."

    init(defaults: UserDefaults = .standard) {
        let bookmarkStore = AgentBridgeBookmarkStore(defaults: defaults)
        self.bookmarkStore = bookmarkStore
        preferenceDefaults = defaults
        isEnabled = defaults.bool(forKey: Self.enabledPreferenceKey)

        do {
            bearerToken = try AFMBridgeBearerTokenGenerator.generate()
            tokenErrorDescription = nil
        } catch {
            bearerToken = nil
            tokenErrorDescription = error.localizedDescription
        }

        do {
            let resolvedPath = try bookmarkStore.resolvedURL()?.path()
            baseDirectoryPath = resolvedPath
            status = resolvedPath == nil ? .notConfigured : .off
            errorMessage = nil
        } catch {
            baseDirectoryPath = nil
            status = .failed
            errorMessage = String(
                localized: "The saved bridge folder could not be restored: \(error.localizedDescription)"
            )
        }
    }

    var isTransitioning: Bool {
        status == .starting || status == .stopping
    }

    var canToggleEnabled: Bool {
        !isTransitioning && (isEnabled || bookmarkStore.hasBookmark)
    }

    var statusTitle: String {
        switch status {
        case .notConfigured:
            String(localized: "Choose a folder")
        case .off:
            String(localized: "Off")
        case .starting:
            String(localized: "Starting")
        case .running:
            String(localized: "Running")
        case .stopping:
            String(localized: "Stopping")
        case .failed:
            String(localized: "Needs attention")
        }
    }

    func selectBaseDirectory(_ directoryURL: URL) {
        guard !isEnabled, !isTransitioning else { return }

        do {
            try bookmarkStore.save(directoryURL)
            baseDirectoryPath = try bookmarkStore.resolvedURL()?.path()
            status = .off
            errorMessage = nil
        } catch {
            errorMessage = String(
                localized: "The bridge folder could not be saved: \(error.localizedDescription)"
            )
        }
    }

    func handleDirectorySelectionFailure(_ error: any Swift.Error) {
        let cocoaError = error as NSError
        guard !(cocoaError.domain == NSCocoaErrorDomain && cocoaError.code == NSUserCancelledError) else {
            return
        }
        errorMessage = String(localized: "The bridge folder could not be selected: \(error.localizedDescription)")
    }

    func handleEmptyDirectorySelection() {
        errorMessage = Error.emptySelection.localizedDescription
    }

    func activatePersistedPreference() {
        guard !hasActivated else { return }
        hasActivated = true
        if isEnabled {
            scheduleReconciliation()
        }
    }
}

private extension AgentBridgeController {
    private func scheduleReconciliation() {
        guard reconciliationTask == nil else { return }
        reconciliationTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await reconcileEnabledState()
            reconciliationTask = nil
        }
    }

    private func reconcileEnabledState() async {
        while true {
            if status == .failed, hasActiveResources {
                await retryFailedCleanup()
                return
            }

            if isEnabled, !hasActiveResources {
                await start()
                guard status == .running else {
                    if status == .failed, hasActiveResources {
                        continue
                    }
                    if !isEnabled {
                        resetDisabledStatus()
                    }
                    return
                }
            } else if !isEnabled, hasActiveResources {
                await stop()
                if hasActiveResources {
                    continue
                }
            } else {
                if !isEnabled { resetDisabledStatus() }
                return
            }
        }
    }

    private var hasActiveResources: Bool {
        server != nil || descriptorLease != nil || activeBaseDirectory != nil || protectsProcessLifetime
    }

    private func start() async {
        status = .starting
        errorMessage = nil
        cleanupFailureContext = nil

        guard let bearerToken else {
            failStart(Error.secureTokenUnavailable(tokenErrorDescription ?? String(localized: "Unknown error")))
            return
        }

        do {
            let baseDirectory = try bookmarkStore.beginAccess()
            await start(bearerToken: bearerToken, baseDirectory: baseDirectory)
        } catch {
            failStart(error)
        }
    }

    private func start(bearerToken: String, baseDirectory: URL) async {
        var newServer: AFMHTTPServer?

        do {
            let startup = try makeStartupConfiguration(
                bearerToken: bearerToken,
                baseDirectory: baseDirectory
            )
            newServer = startup.server
            protectProcessLifetime()
            let address = try await startup.server.start()
            guard case .tcp(let boundHost, let boundPort) = address,
                  boundHost == startup.host else {
                throw Error.unexpectedEndpoint
            }

            let lease = try publishDescriptor(
                startup,
                endpoint: .loopbackTCP(host: boundHost, port: boundPort),
                bearerToken: bearerToken
            )
            server = startup.server
            descriptorLease = lease
            activeBaseDirectory = baseDirectory
            descriptorPath = lease.descriptorPath
            status = .running
        } catch {
            let cleanupFailures = await cleanFailedStart(server: newServer, baseDirectory: baseDirectory)
            failStart(error, cleanupFailures: cleanupFailures)
        }
    }

    private func makeStartupConfiguration(
        bearerToken: String,
        baseDirectory: URL
    ) throws -> StartupConfiguration {
        let bridgeDirectory = baseDirectory.appending(
            path: Self.bridgeDirectoryName,
            directoryHint: .isDirectory
        )
        let bridgeDirectoryPath = bridgeDirectory.path()
        try AFMBridgeDirectory.prepare(at: bridgeDirectoryPath)

        let catalog = AgentBridgeModelCatalog()
        let modelIdentifiers = catalog.models().map(\.id).sorted()
        guard !modelIdentifiers.isEmpty else { throw Error.noAvailableModels }

        let configuration = AFMServerConfiguration(
            endpoint: .tcp(host: Self.loopbackHost, port: 0),
            security: .init(bearerToken: bearerToken)
        )
        let generator = AFMFoundationModelsChatGenerator(
            toolSessionBuilder: AgentBridgeSessionBuilder.makeSession
        )
        let server = try AFMHTTPServer(
            configuration: configuration,
            catalog: catalog,
            generator: generator
        )
        return StartupConfiguration(
            server: server,
            directoryPath: bridgeDirectoryPath,
            host: Self.loopbackHost,
            modelIdentifiers: modelIdentifiers
        )
    }

    private func publishDescriptor(
        _ startup: StartupConfiguration,
        endpoint: AFMBridgeEndpoint,
        bearerToken: String
    ) throws -> AFMBridgeDescriptorLease {
        let descriptorStore = try AFMBridgeDescriptorStore(directoryPath: startup.directoryPath)
        let descriptor = AFMBridgeConnectionDescriptor(
            endpoint: endpoint,
            bearerToken: bearerToken,
            processIdentifier: ProcessInfo.processInfo.processIdentifier,
            launchIdentifier: launchIdentifier,
            modelIdentifiers: startup.modelIdentifiers,
            startedAt: .now
        )
        return try descriptorStore.publish(descriptor)
    }

    private func cleanFailedStart(server: AFMHTTPServer?, baseDirectory: URL) async -> [String] {
        if let server {
            self.server = server
        }
        activeBaseDirectory = baseDirectory
        return await cleanActiveResources()
    }

    private func stop() async {
        status = .stopping
        let failures = await cleanActiveResources()

        if failures.isEmpty {
            cleanupFailureContext = nil
            status = bookmarkStore.hasBookmark ? .off : .notConfigured
            errorMessage = nil
        } else {
            let context = String(localized: "The bridge could not stop completely.")
            cleanupFailureContext = context
            status = .failed
            errorMessage = cleanupFailureMessage(context: context, failures: failures)
        }
    }

    private func retryFailedCleanup() async {
        let context = cleanupFailureContext
            ?? errorMessage
            ?? String(localized: "The bridge cleanup did not finish.")
        let failures = await cleanActiveResources()

        if failures.isEmpty {
            cleanupFailureContext = nil
            if isEnabled {
                status = .failed
                errorMessage = context
            } else {
                resetDisabledStatus()
            }
        } else {
            cleanupFailureContext = context
            status = .failed
            errorMessage = cleanupFailureMessage(context: context, failures: failures)
        }
    }

    private func cleanActiveResources() async -> [String] {
        var failures: [String] = []

        if let descriptorLease {
            do {
                try descriptorLease.cleanup()
                self.descriptorLease = nil
                descriptorPath = nil
            } catch {
                failures.append(error.localizedDescription)
            }
        }

        if let server {
            do {
                try await server.stop()
                self.server = nil
            } catch {
                failures.append(error.localizedDescription)
            }
        }

        if server == nil, descriptorLease == nil {
            activeBaseDirectory?.stopAccessingSecurityScopedResource()
            activeBaseDirectory = nil
            releaseProcessLifetimeProtection()
        }
        return failures
    }

    private func failStart(_ error: any Swift.Error, cleanupFailures: [String] = []) {
        if descriptorLease == nil {
            descriptorPath = nil
        }
        status = .failed
        let context = String(localized: "The bridge could not start: \(error.localizedDescription)")

        if cleanupFailures.isEmpty {
            cleanupFailureContext = nil
            errorMessage = context
        } else {
            cleanupFailureContext = context
            errorMessage = cleanupFailureMessage(context: context, failures: cleanupFailures)
        }
    }

    private func cleanupFailureMessage(context: String, failures: [String]) -> String {
        String(localized: "\(context) Cleanup: \(failures.joined(separator: " "))")
    }

    private func resetDisabledStatus() {
        cleanupFailureContext = nil
        status = bookmarkStore.hasBookmark ? .off : .notConfigured
        errorMessage = nil
    }

    private func protectProcessLifetime() {
        guard !protectsProcessLifetime else { return }
        let processInfo = ProcessInfo.processInfo
        processInfo.disableSuddenTermination()
        processInfo.disableAutomaticTermination(Self.terminationReason)
        protectsProcessLifetime = true
    }

    private func releaseProcessLifetimeProtection() {
        guard protectsProcessLifetime else { return }
        let processInfo = ProcessInfo.processInfo
        processInfo.enableAutomaticTermination(Self.terminationReason)
        processInfo.enableSuddenTermination()
        protectsProcessLifetime = false
    }

    private struct StartupConfiguration {
        let server: AFMHTTPServer
        let directoryPath: String
        let host: String
        let modelIdentifiers: [String]
    }
}
#endif
