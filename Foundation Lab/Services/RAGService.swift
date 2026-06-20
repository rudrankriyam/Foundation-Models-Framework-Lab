//
//  RAGService.swift
//  FoundationLab
//
//  Service for RAG document indexing and search operations.
//

import Foundation
import LumoKit
import VecturaKit

// LumoKit 2.0 predates complete Swift 6 annotations. Both types are safe to
// transfer: LumoKit owns only immutable configuration plus a VecturaKit actor,
// and ChunkingConfig is an immutable value composed of value types.
extension LumoKit: @unchecked @retroactive Sendable {}
extension ChunkingConfig: @unchecked @retroactive Sendable {}

/// Service handling RAG indexing operations.
@MainActor
final class RAGService {
    private let lumoKit: LumoKit
    private let chunkingConfig: ChunkingConfig

    init(lumoKit: LumoKit, chunkingConfig: ChunkingConfig) {
        self.lumoKit = lumoKit
        self.chunkingConfig = chunkingConfig
    }

    func indexDocument(url: URL) async throws -> [UUID] {
        let readableURL = try await Self.copyImportedDocumentToAppStorage(from: url)

        do {
            return try await lumoKit.parseAndIndex(url: readableURL, chunkingConfig: chunkingConfig)
        } catch {
            await Self.removeImportedDocumentIfPossible(at: readableURL)
            throw error
        }
    }

    func indexText(_ text: String) async throws -> [UUID] {
        let chunks = try lumoKit.chunkText(text, config: chunkingConfig)
        return try await lumoKit.addDocuments(texts: chunks.map { $0.text })
    }

    func search(query: String) async throws -> [VecturaSearchResult] {
        try await lumoKit.semanticSearch(query: query, numResults: 5, threshold: 0.5)
    }

    func resetDatabase() async throws {
        try await lumoKit.resetDB()
        // Keep the user-visible reset consistent even if cached import cleanup fails.
        await Self.removeImportedDocumentsIfPossible()
    }

    var documentCount: Int {
        get async throws {
            try await lumoKit.documentCount()
        }
    }
}

private extension RAGService {
    @concurrent
    nonisolated static func copyImportedDocumentToAppStorage(from url: URL) async throws -> URL {
        try Task.checkCancellation()

        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let importsDirectory = try importsDirectoryURL()
        try FileManager.default.createDirectory(
            at: importsDirectory,
            withIntermediateDirectories: true
        )

        let fileName = url.lastPathComponent.isEmpty ? "ImportedDocument" : url.lastPathComponent
        let destinationURL = importsDirectory.appendingPathComponent("\(UUID().uuidString)-\(fileName)")

        do {
            try Task.checkCancellation()
            try FileManager.default.copyItem(at: url, to: destinationURL)
            try Task.checkCancellation()
            return destinationURL
        } catch {
            try? FileManager.default.removeItem(at: destinationURL)
            throw error
        }
    }

    nonisolated static func importsDirectoryURL() throws -> URL {
        try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appendingPathComponent("RAGImports", isDirectory: true)
    }

    @concurrent
    nonisolated static func removeImportedDocumentsIfPossible() async {
        guard !Task.isCancelled,
              let importsDirectory = try? importsDirectoryURL(),
              FileManager.default.fileExists(atPath: importsDirectory.path) else {
            return
        }
        try? FileManager.default.removeItem(at: importsDirectory)
    }

    @concurrent
    nonisolated static func removeImportedDocumentIfPossible(at url: URL) async {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Configuration

struct RAGConfig {
    let searchOptions: VecturaConfig.SearchOptions
    let chunkingConfig: ChunkingConfig

    static func makeDefault() throws -> RAGConfig {
        let options = VecturaConfig.SearchOptions(defaultNumResults: 5, minThreshold: 0.5)
        let chunking = try ChunkingConfig(
            chunkSize: 500,
            overlapPercentage: 0.15,
            strategy: .semantic,
            contentType: .prose
        )
        return RAGConfig(searchOptions: options, chunkingConfig: chunking)
    }
}
