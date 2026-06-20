//
//  RAGChatViewModel.swift
//  FoundationLab
//
//  View model for RAG chat functionality.
//

import Foundation
import FoundationLabCore
import FoundationModels
@preconcurrency import LumoKit
@preconcurrency import VecturaKit

// MARK: - Sample Documents

private enum SampleDocuments {
    static let texts: [(title: String, text: String)] = [
        ("Swift Concurrency", """
        Swift's concurrency model provides a safe and efficient way to write concurrent code. \
        Key concepts include async/await, actors, and structured concurrency. \
        The @MainActor attribute ensures code runs on the main thread. \
        Task groups allow parallel execution of child tasks. \
        Sendable protocol ensures data can be safely transferred between concurrent contexts.
        """),
        ("Foundation Models", """
        The Foundation Models framework enables AI-powered features in iOS apps. \
        SystemLanguageModel provides access to on-device language models. \
        LanguageModelSession manages conversation context and history. \
        Structured generation allows parsing responses into custom types. \
        Streaming responses enable real-time output display.
        """),
        ("HealthKit", """
        HealthKit provides a central repository for health and fitness data. \
        HKObserverQuery monitors changes to health data in real-time. \
        Background delivery enables efficient data synchronization. \
        Sample types include workouts, heart rate, and sleep analysis. \
        Authorization requires user permission for each data type.
        """)
    ]
}

// MARK: - RAG Chat View Model

@MainActor
@Observable
final class RAGChatViewModel {
    var conversation: [RAGChatEntry] = []
    var isSearching = false
    var isGenerating = false
    var showDocumentPicker = false
    var indexedDocumentCount = 0
    var hasIndexedContent = false
    var errorMessage: String?
    var showError = false

    /// Token count from the last RAG generation.
    private(set) var lastTokenCount: Int?

    private var streamingTask: Task<Void, Error>?
    private var service: RAGService?
    private var isInitialized = false
    private var config: RAGConfig?
    private let streamingTextUseCase = StreamTextGenerationUseCase()

    // Store titles per source key (for text/samples) and per chunk UUID (for files)
    private var sourceTitles: [String: String] = [:]
    private var chunkTitles: [String: String] = [:]
    private var indexedURLs: Set<String> = []

    private let userDefaults = UserDefaults.standard
    private let indexedURLsKey = "ragIndexedURLs"
    private let sourceTitlesKey = "ragSourceTitles"
    private let chunkTitlesKey = "ragChunkTitles"

    init() {
        indexedURLs = Set(userDefaults.stringArray(forKey: indexedURLsKey) ?? [])
        if let titlesData = userDefaults.dictionary(forKey: sourceTitlesKey) {
            sourceTitles = titlesData.compactMapValues { $0 as? String }
        }
        if let chunkData = userDefaults.dictionary(forKey: chunkTitlesKey) {
            chunkTitles = chunkData.compactMapValues { $0 as? String }
        }
        indexedDocumentCount = indexedURLs.count
        hasIndexedContent = indexedDocumentCount > 0
        do {
            config = try RAGConfig.makeDefault()
        } catch {
            config = nil
            errorMessage = "Failed to initialize RAG configuration: \(error.localizedDescription)"
            showError = true
        }
    }
}

extension RAGChatViewModel {
    func loadFromDatabase() async {
        guard !isInitialized else { return }
        guard let config = config else {
            errorMessage = errorMessage ?? "RAG configuration is not available"
            showError = true
            return
        }

        do {
            let lumoKit = try await LumoKit(
                config: VecturaConfig(name: "foundation-lab-rag", searchOptions: config.searchOptions),
                chunkingConfig: config.chunkingConfig
            )
            service = RAGService(lumoKit: lumoKit, chunkingConfig: config.chunkingConfig)

            let dbCount = try await lumoKit.documentCount()
            if dbCount == 0 && !indexedURLs.isEmpty {
                indexedURLs.removeAll()
                sourceTitles.removeAll()
                chunkTitles.removeAll()
                saveState()
            }
            indexedDocumentCount = indexedURLs.count
            hasIndexedContent = dbCount > 0
            isInitialized = true
        } catch {
            errorMessage = "Failed to initialize RAG: \(error.localizedDescription)"
            showError = true
        }
    }

    func indexDocument(from url: URL) async {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return
        }

        let urlKey = url.absoluteString
        guard !indexedURLs.contains(urlKey) else {
            errorMessage = "This document has already been indexed"
            showError = true
            return
        }

        isSearching = true
        do {
            let ids = try await service.indexDocument(url: url)
            indexedURLs.insert(urlKey)
            sourceTitles[urlKey] = url.lastPathComponent
            for id in ids { chunkTitles[id.uuidString] = url.lastPathComponent }
            saveState()
            indexedDocumentCount += 1
            hasIndexedContent = true
        } catch {
            errorMessage = "Failed to index document: \(error.localizedDescription)"
            showError = true
        }
        isSearching = false
    }

    func indexText(_ text: String, title: String) async {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return
        }

        let urlKey = "text://\(title)"
        guard !indexedURLs.contains(urlKey) else {
            errorMessage = "A document with this title already exists"
            showError = true
            return
        }

        isSearching = true
        do {
            let ids = try await service.indexText(text)
            indexedURLs.insert(urlKey)
            sourceTitles[urlKey] = title
            for id in ids { chunkTitles[id.uuidString] = title }
            saveState()
            indexedDocumentCount += 1
            hasIndexedContent = true
        } catch {
            errorMessage = "Failed to index text: \(error.localizedDescription)"
            showError = true
        }
        isSearching = false
    }

    func resetDatabase() async {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return
        }

        do {
            try await service.resetDatabase()
            indexedURLs.removeAll()
            sourceTitles.removeAll()
            chunkTitles.removeAll()
            saveState()
            indexedDocumentCount = 0
            hasIndexedContent = false
        } catch {
            errorMessage = "Failed to reset database: \(error.localizedDescription)"
            showError = true
        }
    }

    func loadSampleDocuments() async {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return
        }

        isSearching = true
        var newCount = 0
        var firstError: Error?

        for (title, text) in SampleDocuments.texts {
            let urlKey = "sample://\(title)"
            guard !indexedURLs.contains(urlKey) else { continue }

            do {
                let ids = try await service.indexText(text)
                indexedURLs.insert(urlKey)
                sourceTitles[urlKey] = title
                for id in ids {
                    chunkTitles[id.uuidString] = title
                }
                newCount += 1
                saveState()
            } catch {
                if firstError == nil {
                    firstError = error
                }
            }
        }

        indexedDocumentCount += newCount
        if newCount > 0 {
            hasIndexedContent = true
        }

        if let error = firstError {
            errorMessage = "Failed to load samples: \(error.localizedDescription)"
            showError = true
        }
        isSearching = false
    }

    func askQuestion(
        _ content: String,
        onSources: @escaping @MainActor ([RAGChunk]) -> Void,
        onUpdate: @escaping @MainActor (String) -> Void
    ) async {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        guard hasIndexedContent || indexedDocumentCount > 0 else {
            errorMessage = "Index documents before asking a question."
            showError = true
            return
        }

        guard !isSearching && !isGenerating else { return }

        let chunks = await searchDocuments(service: service, query: trimmedContent)
        let topChunks = Array(chunks.prefix(2))
        onSources(topChunks)

        guard !topChunks.isEmpty else {
            onUpdate("No sources found for that question. Try asking about a specific section or rephrase your question.")
            return
        }

        await generateAnswer(query: trimmedContent, chunks: topChunks, onUpdate: onUpdate)
    }

    func sendMessage(_ content: String) async -> Bool {
        await loadFromDatabase()
        guard let service = service else {
            showServiceUnavailableError()
            return false
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return false }

        guard hasIndexedContent || indexedDocumentCount > 0 else {
            errorMessage = "Index documents before starting a RAG chat."
            showError = true
            return false
        }

        guard !isSearching && !isGenerating else { return false }

        let userEntry = RAGChatEntry(role: .user, content: trimmedContent, sources: [])
        conversation.append(userEntry)

        let chunks = await searchDocuments(service: service, query: trimmedContent)
        let assistantEntry = RAGChatEntry(role: .assistant, content: "", sources: chunks)
        conversation.append(assistantEntry)

        await generateResponse(for: assistantEntry, query: trimmedContent, chunks: chunks)
        return true
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    func tearDown() {
        streamingTask?.cancel()
        streamingTask = nil
    }
}

private extension RAGChatViewModel {
    func showServiceUnavailableError() {
        errorMessage = "RAG service is not available. Please restart the app."
        showError = true
    }

    func saveState() {
        userDefaults.set(Array(indexedURLs), forKey: indexedURLsKey)
        userDefaults.set(sourceTitles, forKey: sourceTitlesKey)
        userDefaults.set(chunkTitles, forKey: chunkTitlesKey)
    }

    func searchDocuments(service: RAGService, query: String) async -> [RAGChunk] {
        isSearching = true
        defer { isSearching = false }
        var chunks: [RAGChunk] = []

        do {
            let results = try await service.search(query: query)
            chunks = results.map { result in
                // Look up title from chunk ID mapping
                let title = chunkTitles[result.id.uuidString] ?? sourceTitlesForChunk(result.id.uuidString)
                return RAGChunk(
                    documentId: result.id.uuidString,
                    documentTitle: title,
                    content: result.text,
                    chunkIndex: 0,
                    similarityScore: Double(result.score)
                )
            }
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
            showError = true
        }

        return chunks
    }

    func sourceTitlesForChunk(_ chunkId: String) -> String {
        if sourceTitles.count == 1 {
            return sourceTitles.values.first ?? "Source"
        }
        return "Source"
    }

    func generateAnswer(query: String, chunks: [RAGChunk], onUpdate: @escaping @MainActor (String) -> Void) async {
        isGenerating = true
        defer { isGenerating = false }
        lastTokenCount = nil

        let systemPrompt = """
        You are a helpful assistant. Answer using only the sources provided.
        Cite sources with [1], [2]. If the sources do not contain the answer, say you don't know.
        """
        let contextText = chunks.isEmpty ? "No sources available." :
            chunks.enumerated().map { index, chunk in "[\(index + 1)] \(chunk.content)" }.joined(separator: "\n\n")
        let prompt = "SOURCES:\n\(contextText)\n\nQUESTION:\n\(query)"

        do {
            streamingTask?.cancel()
            let request = StreamingTextGenerationRequest(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelUseCase: .general,
                context: CapabilityInvocationContext(source: .app)
            )
            let task = Task { @MainActor [streamingTextUseCase] in
                let result = try await streamingTextUseCase.execute(request) { partialResponse in
                    await onUpdate(partialResponse)
                }
                self.lastTokenCount = result.metadata.tokenCount
            }
            streamingTask = task
            defer { streamingTask = nil }
            do {
                try await task.value
            } catch is CancellationError {
                return
            }
        } catch {
            onUpdate("Failed to answer: \(error.localizedDescription)")
        }
    }

    func generateResponse(for entry: RAGChatEntry, query: String, chunks: [RAGChunk]) async {
        isGenerating = true
        defer { isGenerating = false }
        lastTokenCount = nil

        let systemPrompt = "You are a helpful assistant. Answer based on context. Cite content when possible."
        let contextText = chunks.isEmpty ? "No relevant documents found." :
            chunks.enumerated().map { index, chunk in "[Document \(index + 1)]: \(chunk.content)" }.joined(separator: "\n\n")
        let prompt = "CONTEXT:\n\(contextText)\n\nQUESTION:\n\(query)"

        do {
            streamingTask?.cancel()
            let request = StreamingTextGenerationRequest(
                prompt: prompt,
                systemPrompt: systemPrompt,
                modelUseCase: .general,
                context: CapabilityInvocationContext(source: .app)
            )
            let task = Task { @MainActor [streamingTextUseCase] in
                let result = try await streamingTextUseCase.execute(request) { partialResponse in
                    await self.updateStreamingEntry(entry, with: partialResponse)
                }
                self.lastTokenCount = result.metadata.tokenCount
            }
            streamingTask = task
            defer { streamingTask = nil }
            do {
                try await task.value
            } catch is CancellationError {
                return
            }
        } catch {
            if entry.content.isEmpty { entry.content = "Failed: \(error.localizedDescription)" }
        }
    }

    @MainActor
    private func updateStreamingEntry(_ entry: RAGChatEntry, with partialResponse: String) {
        entry.content = partialResponse
    }
}
