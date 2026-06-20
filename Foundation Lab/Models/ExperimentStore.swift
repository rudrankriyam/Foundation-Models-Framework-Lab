//
//  ExperimentStore.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore
import Observation

@MainActor
@Observable
final class ExperimentStore {
    private static let fallback = ExperimentStore()
    private static weak var activeStore: ExperimentStore?

    static var shared: ExperimentStore {
        activeStore ?? fallback
    }

    var activeExperiment: FoundationLabExperimentConfiguration {
        didSet {
            guard !isNormalizingActiveExperiment else { return }

            let normalizedExperiment = activeExperiment.normalized
            if normalizedExperiment != activeExperiment {
                isNormalizingActiveExperiment = true
                activeExperiment = normalizedExperiment
                isNormalizingActiveExperiment = false
            }
            scheduleActiveExperimentPersistence(normalizedExperiment)
        }
    }

    /// Changes only when another configuration replaces the active experiment.
    /// Bound edits intentionally do not affect this value.
    private(set) var activeExperimentLoadRevision = 0

    var savedExperiments: [FoundationLabExperimentConfiguration] {
        libraryRepository.savedExperiments
    }

    var runs: [FoundationLabExperimentRun] {
        libraryRepository.runs
    }

    var persistenceErrorMessage: String? {
        activePersistenceErrorMessage ?? libraryRepository.persistenceErrorMessage
    }

    var hasUnsavedActiveExperiment: Bool {
        guard let savedExperiment = savedExperiments.first(where: { $0.id == activeExperiment.id }) else {
            return true
        }
        return Self.comparableConfiguration(activeExperiment)
            != Self.comparableConfiguration(savedExperiment)
    }

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let activeExperimentKey: String
    @ObservationIgnored private let activeExperimentEncoder: JSONEncoder
    @ObservationIgnored private let libraryRepository: ExperimentLibraryRepository
    @ObservationIgnored private var isNormalizingActiveExperiment = false
    @ObservationIgnored private var activeExperimentPersistenceTask: Task<Bool, Never>?
    @ObservationIgnored private var hasPendingActivationState = false
    private var activePersistenceErrorMessage: String?

    init(
        userDefaults: UserDefaults = .standard,
        activeExperimentKey: String = "foundationLab.activeExperiment",
        libraryRepository: ExperimentLibraryRepository? = nil,
        storageDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let decoder = JSONDecoder()
        let restoredActiveExperiment = ExperimentPersistenceRepository.restoreActiveExperiment(
            from: userDefaults,
            key: activeExperimentKey,
            decoder: decoder
        )

        self.userDefaults = userDefaults
        self.activeExperimentKey = activeExperimentKey
        activeExperimentEncoder = encoder
        self.libraryRepository = libraryRepository ?? Self.makeLibraryRepository(
            userDefaults: userDefaults,
            storageDirectory: storageDirectory,
            fileManager: fileManager
        )
        activeExperiment = (
            restoredActiveExperiment.value
                ?? FoundationLabExperimentConfiguration(name: "")
        ).normalized
        activePersistenceErrorMessage = restoredActiveExperiment.failed
            ? "Couldn’t restore the active experiment. Your library is still available."
            : nil
        activeExperimentPersistenceTask = nil
    }
}

extension ExperimentStore {
    func activate() {
        if Self.activeStore == nil,
           self !== Self.fallback,
           Self.fallback.hasPendingActivationState {
            let pendingExperiment = Self.fallback.activeExperiment
            Self.fallback.hasPendingActivationState = false
            load(pendingExperiment)
        }

        Self.activeStore = self
    }

    func load(_ configuration: FoundationLabExperimentConfiguration) {
        activeExperiment = configuration.normalized
        activeExperimentLoadRevision += 1
        markPendingActivationStateIfNeeded()
    }

    @discardableResult
    func newExperiment() -> FoundationLabExperimentConfiguration {
        let experiment = FoundationLabExperimentConfiguration(name: "")
        activeExperiment = experiment
        activeExperimentLoadRevision += 1
        markPendingActivationStateIfNeeded()
        return experiment
    }

    func updateActiveExperiment(_ configuration: FoundationLabExperimentConfiguration) {
        var updatedConfiguration = configuration
        updatedConfiguration.modifiedAt = .now
        activeExperiment = updatedConfiguration.normalized
        markPendingActivationStateIfNeeded()
    }

    func updateActiveExperiment(
        _ update: (inout FoundationLabExperimentConfiguration) -> Void
    ) {
        var updatedExperiment = activeExperiment
        update(&updatedExperiment)
        updatedExperiment.modifiedAt = .now
        activeExperiment = updatedExperiment.normalized
        markPendingActivationStateIfNeeded()
    }

    @discardableResult
    func saveActiveExperiment() async -> FoundationLabExperimentConfiguration {
        let savedConfiguration = libraryRepository.save(activeExperiment)
        activeExperiment = savedConfiguration
        await flushPendingPersistence()
        return savedConfiguration
    }

    @discardableResult
    func save(
        _ configuration: FoundationLabExperimentConfiguration
    ) async -> FoundationLabExperimentConfiguration {
        let savedConfiguration = libraryRepository.save(configuration)
        if activeExperiment.id == savedConfiguration.id {
            activeExperiment = savedConfiguration
        }
        await flushPendingPersistence()
        return savedConfiguration
    }

    func record(_ run: FoundationLabExperimentRun) {
        libraryRepository.record(run)
    }

    func deleteSavedExperiment(id: UUID) {
        libraryRepository.deleteSavedExperiment(id: id)
    }

    func clearSavedExperiments() {
        libraryRepository.clearSavedExperiments()
    }

    func deleteRun(id: UUID) {
        libraryRepository.deleteRun(id: id)
    }

    func deleteRuns(ids: Set<UUID>) {
        libraryRepository.deleteRuns(ids: ids)
    }

    func clearRuns() {
        libraryRepository.clearRuns()
    }

    func clearPersistenceError() {
        activePersistenceErrorMessage = nil
        libraryRepository.clearPersistenceError()
    }

    @discardableResult
    func retryPersistence() async -> Bool {
        activeExperimentPersistenceTask?.cancel()
        activeExperimentPersistenceTask = nil
        let didPersistActiveExperiment = persistActiveExperimentImmediately(
            activeExperiment.normalized
        )
        let didPersistLibrary = await libraryRepository.retryPersistence()
        return didPersistActiveExperiment && didPersistLibrary
    }

    /// Flushes both the debounced active draft and the latest library snapshot.
    @discardableResult
    func flushPendingPersistence() async -> Bool {
        activeExperimentPersistenceTask?.cancel()
        activeExperimentPersistenceTask = nil
        let didPersistActiveExperiment = persistActiveExperimentImmediately(
            activeExperiment.normalized
        )
        let didPersistLibrary = await libraryRepository.flushPendingPersistence()
        return didPersistActiveExperiment && didPersistLibrary
    }
}

private extension ExperimentStore {
    static let activeSaveFailureMessage =
        "Your active experiment couldn’t be saved. You can keep working and retry."

    static func makeLibraryRepository(
        userDefaults: UserDefaults,
        storageDirectory: URL?,
        fileManager: FileManager
    ) -> ExperimentLibraryRepository {
        if storageDirectory == nil, userDefaults === UserDefaults.standard {
            return .shared
        }

        let directory = storageDirectory ?? URL.temporaryDirectory.appending(
            path: "FoundationLab-Ephemeral-\(UUID().uuidString)",
            directoryHint: .isDirectory
        )
        return ExperimentLibraryRepository(
            userDefaults: userDefaults,
            storageDirectory: directory,
            fileManager: fileManager
        )
    }

    static func comparableConfiguration(
        _ configuration: FoundationLabExperimentConfiguration
    ) -> FoundationLabExperimentConfiguration {
        var comparableConfiguration = configuration.normalized
        comparableConfiguration.modifiedAt = comparableConfiguration.createdAt
        return comparableConfiguration
    }

    @discardableResult
    func persistActiveExperimentImmediately(
        _ experiment: FoundationLabExperimentConfiguration
    ) -> Bool {
        do {
            userDefaults.set(
                try activeExperimentEncoder.encode(experiment),
                forKey: activeExperimentKey
            )
            activePersistenceErrorMessage = nil
            return true
        } catch {
            activePersistenceErrorMessage = Self.activeSaveFailureMessage
            return false
        }
    }

    func scheduleActiveExperimentPersistence(
        _ experiment: FoundationLabExperimentConfiguration
    ) {
        activeExperimentPersistenceTask?.cancel()
        activeExperimentPersistenceTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(250))
            } catch {
                return false
            }
            guard !Task.isCancelled, let self else { return false }
            return self.persistActiveExperimentImmediately(experiment)
        }
    }

    func markPendingActivationStateIfNeeded() {
        if Self.activeStore == nil, self === Self.fallback {
            hasPendingActivationState = true
        }
    }
}
