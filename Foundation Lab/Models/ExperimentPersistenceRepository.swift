//
//  ExperimentPersistenceRepository.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore
import FoundationModelsKit

actor ExperimentPersistenceRepository {
    static let currentSchemaVersion = 1

    private static let legacySavedExperimentsKey = "foundationLab.savedExperiments"
    private static let legacyRunsKey = "foundationLab.experimentRuns"
    private static let storageFileName = "experiment-library-v1.json"

    private let storageURL: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private var latestAttemptedRevision = 0

    init(storageURL: URL) {
        self.storageURL = storageURL
        encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
    }

    /// Returns false when a newer snapshot reached the repository first.
    func write(_ document: ExperimentPersistenceDocument, revision: Int) throws -> Bool {
        guard !Task.isCancelled, revision >= latestAttemptedRevision else { return false }
        latestAttemptedRevision = revision

        let data = try encoder.encode(document)
        try fileManager.createDirectory(
            at: storageURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try data.write(to: storageURL, options: .atomic)
        return true
    }

    nonisolated static func storageURL(for directory: URL?) -> URL {
        (directory ?? defaultStorageDirectory)
            .appending(path: storageFileName)
    }

    @MainActor
    static func restoreActiveExperiment(
        from userDefaults: UserDefaults,
        key: String,
        decoder: JSONDecoder
    ) -> ExperimentValueRestoration<FoundationLabExperimentConfiguration> {
        guard let data = userDefaults.data(forKey: key) else {
            return ExperimentValueRestoration(value: nil, failed: false)
        }

        do {
            let experiment = try decoder.decode(
                FoundationLabExperimentConfiguration.self,
                from: data
            )
            return ExperimentValueRestoration(value: experiment, failed: false)
        } catch {
            return ExperimentValueRestoration(value: nil, failed: true)
        }
    }

    @MainActor
    static func restoreCollections(
        from storageURL: URL,
        userDefaults: UserDefaults,
        fileManager: FileManager,
        decoder: JSONDecoder
    ) -> ExperimentCollectionRestoration {
        guard fileManager.fileExists(atPath: storageURL.path) else {
            return restoreLegacyCollections(from: userDefaults, decoder: decoder)
        }

        do {
            let document = try decoder.decode(
                ExperimentPersistenceDocument.self,
                from: Data(contentsOf: storageURL)
            )
            guard document.schemaVersion <= currentSchemaVersion else {
                return ExperimentCollectionRestoration(
                    document: emptyDocument,
                    message: "the experiment library because it was created by a newer app version",
                    blocksWrites: true
                )
            }
            return ExperimentCollectionRestoration(
                document: document,
                message: document.discardedElementCount == 0
                    ? nil
                    : "some damaged experiment library entries",
                shouldPersist: document.discardedElementCount > 0
            )
        } catch {
            guard backUpCorruptStorageFile(at: storageURL, fileManager: fileManager) else {
                return ExperimentCollectionRestoration(
                    document: emptyDocument,
                    message: "the experiment library because its file is unreadable",
                    blocksWrites: true
                )
            }

            var legacyRestoration = restoreLegacyCollections(
                from: userDefaults,
                decoder: decoder
            )
            legacyRestoration.message = "the damaged experiment library; a backup was preserved"
            legacyRestoration.shouldPersist = true
            return legacyRestoration
        }
    }

    @MainActor
    static func removeLegacyValues(from userDefaults: UserDefaults) {
        userDefaults.removeObject(forKey: legacySavedExperimentsKey)
        userDefaults.removeObject(forKey: legacyRunsKey)
    }
}

nonisolated struct ExperimentValueRestoration<Value: Sendable>: Sendable {
    let value: Value?
    let failed: Bool
}

nonisolated struct ExperimentCollectionRestoration: Sendable {
    var document: ExperimentPersistenceDocument
    var message: String?
    var shouldPersist = false
    var removeLegacyValuesAfterPersisting = false
    var blocksWrites = false
}

private extension ExperimentPersistenceRepository {
    @MainActor
    static func restoreLegacyCollections(
        from userDefaults: UserDefaults,
        decoder: JSONDecoder
    ) -> ExperimentCollectionRestoration {
        let experiments: ExperimentDecodedCollection<FoundationLabExperimentConfiguration>
        let runs: ExperimentDecodedCollection<FoundationLabExperimentRun>
        var hadFailures = false

        do {
            experiments = try restoreLegacyCollection(
                FoundationLabExperimentConfiguration.self,
                from: userDefaults,
                key: legacySavedExperimentsKey,
                decoder: decoder
            )
        } catch {
            experiments = ExperimentDecodedCollection(values: [], discardedElementCount: 0)
            hadFailures = true
        }

        do {
            runs = try restoreLegacyCollection(
                FoundationLabExperimentRun.self,
                from: userDefaults,
                key: legacyRunsKey,
                decoder: decoder
            )
        } catch {
            runs = ExperimentDecodedCollection(values: [], discardedElementCount: 0)
            hadFailures = true
        }

        let hadLegacyValues = userDefaults.object(forKey: legacySavedExperimentsKey) != nil
            || userDefaults.object(forKey: legacyRunsKey) != nil
        hadFailures = hadFailures
            || experiments.discardedElementCount > 0
            || runs.discardedElementCount > 0

        return ExperimentCollectionRestoration(
            document: ExperimentPersistenceDocument(
                schemaVersion: currentSchemaVersion,
                savedExperiments: experiments.values,
                runs: runs.values
            ),
            message: hadFailures ? "some legacy experiment library entries" : nil,
            shouldPersist: true,
            removeLegacyValuesAfterPersisting: hadLegacyValues
        )
    }

    @MainActor
    static func restoreLegacyCollection<Element: Decodable & Sendable>(
        _ type: Element.Type,
        from userDefaults: UserDefaults,
        key: String,
        decoder: JSONDecoder
    ) throws -> ExperimentDecodedCollection<Element> {
        guard let data = userDefaults.data(forKey: key) else {
            return ExperimentDecodedCollection(values: [], discardedElementCount: 0)
        }
        return try ExperimentPersistenceDocument.decodeCollection(
            type,
            from: data,
            decoder: decoder
        )
    }

    @MainActor
    static func backUpCorruptStorageFile(
        at storageURL: URL,
        fileManager: FileManager
    ) -> Bool {
        let backupURL = storageURL.deletingLastPathComponent().appending(
            path: "experiment-library-corrupt-\(UUID().uuidString).json"
        )
        do {
            try fileManager.moveItem(at: storageURL, to: backupURL)
            return true
        } catch {
            return false
        }
    }

    nonisolated static var defaultStorageDirectory: URL {
        URL.applicationSupportDirectory
            .appending(path: "Foundation Lab", directoryHint: .isDirectory)
    }

    nonisolated static var emptyDocument: ExperimentPersistenceDocument {
        ExperimentPersistenceDocument(schemaVersion: currentSchemaVersion)
    }
}
