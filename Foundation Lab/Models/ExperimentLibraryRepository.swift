//
//  ExperimentLibraryRepository.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore
import Observation

@MainActor
@Observable
final class ExperimentLibraryRepository {
    static let shared = ExperimentLibraryRepository()

    private(set) var savedExperiments: [FoundationLabExperimentConfiguration] {
        didSet {
            persistCollections()
        }
    }

    private(set) var runs: [FoundationLabExperimentRun] {
        didSet {
            persistCollections()
        }
    }

    private(set) var persistenceErrorMessage: String?

    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let persistenceRepository: ExperimentPersistenceRepository
    @ObservationIgnored private var writesBlocked: Bool
    @ObservationIgnored private var persistenceRevision = 0
    @ObservationIgnored private var persistedRevision = 0
    @ObservationIgnored private var persistenceTask: Task<Bool, Never>?
    @ObservationIgnored private var shouldRemoveLegacyValuesAfterPersisting: Bool

    private static let maximumRunCount = 200

    init(
        userDefaults: UserDefaults = .standard,
        storageDirectory: URL? = nil,
        fileManager: FileManager = .default
    ) {
        let storageURL = ExperimentPersistenceRepository.storageURL(for: storageDirectory)
        let restoration = ExperimentPersistenceRepository.restoreCollections(
            from: storageURL,
            userDefaults: userDefaults,
            fileManager: fileManager,
            decoder: JSONDecoder()
        )
        let restoredExperiments = Self.sanitizedExperiments(
            restoration.document.savedExperiments
        )
        let restoredRuns = Self.sanitizedRuns(restoration.document.runs)

        self.userDefaults = userDefaults
        persistenceRepository = ExperimentPersistenceRepository(
            storageURL: storageURL
        )
        savedExperiments = restoredExperiments
        runs = restoredRuns
        writesBlocked = restoration.blocksWrites
        shouldRemoveLegacyValuesAfterPersisting = restoration.removeLegacyValuesAfterPersisting
        persistenceErrorMessage = restoration.message.map {
            "Couldn’t fully restore \($0). Your in-memory work is still available."
        }

        let restoredValuesChanged = restoredExperiments != restoration.document.savedExperiments
            || restoredRuns != restoration.document.runs
        if restoration.shouldPersist || restoredValuesChanged {
            persistCollections()
        }
    }

    @discardableResult
    func save(
        _ configuration: FoundationLabExperimentConfiguration
    ) -> FoundationLabExperimentConfiguration {
        var savedConfiguration = configuration
        savedConfiguration.modifiedAt = .now
        savedConfiguration.normalize()

        var updatedExperiments = savedExperiments.filter {
            $0.id != savedConfiguration.id
        }
        updatedExperiments.append(savedConfiguration)
        savedExperiments = Self.sanitizedExperiments(updatedExperiments)
        return savedConfiguration
    }

    func record(_ run: FoundationLabExperimentRun) {
        var updatedRuns = runs.filter { $0.id != run.id }
        updatedRuns.append(run)
        runs = Self.sanitizedRuns(updatedRuns)
    }

    func deleteSavedExperiment(id: UUID) {
        savedExperiments.removeAll { $0.id == id }
    }

    func clearSavedExperiments() {
        savedExperiments.removeAll()
    }

    func deleteRun(id: UUID) {
        runs.removeAll { $0.id == id }
    }

    func deleteRuns(ids: Set<UUID>) {
        runs.removeAll { ids.contains($0.id) }
    }

    func clearRuns() {
        runs.removeAll()
    }

    func clearPersistenceError() {
        persistenceErrorMessage = nil
    }

    @discardableResult
    func retryPersistence() async -> Bool {
        guard !writesBlocked else {
            persistenceErrorMessage = Self.newerVersionMessage
            return false
        }

        schedulePersistence()
        return await flushPendingPersistence()
    }

    /// Waits for the newest in-memory library snapshot to reach disk.
    @discardableResult
    func flushPendingPersistence() async -> Bool {
        guard !writesBlocked else {
            persistenceErrorMessage = Self.newerVersionMessage
            return false
        }

        while persistedRevision < persistenceRevision {
            let targetRevision = persistenceRevision
            guard let persistenceTask else {
                persistenceErrorMessage = Self.saveFailureMessage
                return false
            }

            _ = await persistenceTask.value
            guard targetRevision == persistenceRevision else {
                continue
            }

            if persistedRevision < targetRevision {
                persistenceErrorMessage = Self.saveFailureMessage
                return false
            }
        }

        return true
    }
}

private extension ExperimentLibraryRepository {
    static let newerVersionMessage =
        "This experiment library was created by a newer app version and can’t be overwritten."
    static let saveFailureMessage =
        "Your experiment library couldn’t be saved. You can keep working and retry."

    func persistCollections() {
        guard !writesBlocked else {
            persistenceErrorMessage = Self.newerVersionMessage
            return
        }

        schedulePersistence()
    }

    func schedulePersistence() {
        persistenceRevision += 1
        let revision = persistenceRevision
        let document = makePersistenceDocument()

        persistenceTask?.cancel()
        persistenceTask = Task { @MainActor [weak self, persistenceRepository] in
            guard !Task.isCancelled else { return false }

            do {
                let didWrite = try await persistenceRepository.write(
                    document,
                    revision: revision
                )
                guard didWrite, let self else {
                    return false
                }

                self.persistedRevision = max(self.persistedRevision, revision)
                if revision == self.persistenceRevision {
                    self.removeLegacyValuesIfNeeded()
                    self.persistenceErrorMessage = nil
                }
                return true
            } catch {
                if let self, revision == self.persistenceRevision {
                    self.persistenceErrorMessage = Self.saveFailureMessage
                }
                return false
            }
        }
    }

    func makePersistenceDocument() -> ExperimentPersistenceDocument {
        ExperimentPersistenceDocument(
            schemaVersion: ExperimentPersistenceRepository.currentSchemaVersion,
            savedExperiments: savedExperiments,
            runs: runs
        )
    }

    func removeLegacyValuesIfNeeded() {
        guard shouldRemoveLegacyValuesAfterPersisting else { return }
        ExperimentPersistenceRepository.removeLegacyValues(from: userDefaults)
        shouldRemoveLegacyValuesAfterPersisting = false
    }

    static func sanitizedExperiments(
        _ experiments: [FoundationLabExperimentConfiguration]
    ) -> [FoundationLabExperimentConfiguration] {
        var experimentsByID: [UUID: FoundationLabExperimentConfiguration] = [:]
        for experiment in experiments {
            let normalizedExperiment = experiment.normalized
            guard let existingExperiment = experimentsByID[normalizedExperiment.id] else {
                experimentsByID[normalizedExperiment.id] = normalizedExperiment
                continue
            }
            if normalizedExperiment.modifiedAt > existingExperiment.modifiedAt {
                experimentsByID[normalizedExperiment.id] = normalizedExperiment
            }
        }
        return experimentsByID.values.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    static func sanitizedRuns(
        _ runs: [FoundationLabExperimentRun]
    ) -> [FoundationLabExperimentRun] {
        var runsByID: [UUID: FoundationLabExperimentRun] = [:]
        for run in runs {
            guard let existingRun = runsByID[run.id] else {
                runsByID[run.id] = run
                continue
            }
            if run.startedAt > existingRun.startedAt {
                runsByID[run.id] = run
            }
        }
        return Array(
            runsByID.values
                .sorted { $0.startedAt > $1.startedAt }
                .prefix(Self.maximumRunCount)
        )
    }
}
