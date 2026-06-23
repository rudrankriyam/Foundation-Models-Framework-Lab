//
//  SpotlightRAGViewModel.swift
//  FoundationLab
//

#if compiler(>=6.4) && arch(arm64)
import CoreSpotlight
import Foundation
import FoundationModels
import Observation
import UniformTypeIdentifiers
import _CoreSpotlight_FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class SpotlightRAGViewModel {
    static let defaultPrompt = "What did I decide about the Kyoto itinerary?"
    static let domainIdentifier = "com.rudrankriyam.FoundationLab.spotlight-rag"

    var prompt = defaultPrompt
    var answer = ""
    var errorMessage: String?
    var events: [SpotlightRAGSearchEvent] = []
    var matchedDocuments: [SpotlightRAGDocument] = []
    var guidance = SpotlightRAGGuidance.dynamic
    var usesCompactFormat = true
    var isIndexing = false
    var isRunning = false
    var hasIndexedSamples = false

    let sampleDocuments = SpotlightRAGDocument.samples

    private var runTask: Task<Void, Never>?
    private var activeRunID: UUID?

    var canRun: Bool {
        hasIndexedSamples
            && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isIndexing
            && !isRunning
    }

    func indexSamples() async {
        guard !isIndexing else { return }
        isIndexing = true
        errorMessage = nil

        defer { isIndexing = false }

        do {
            let index = CSSearchableIndex.default()
            try await index.deleteSearchableItems(withDomainIdentifiers: [Self.domainIdentifier])
            try await index.indexSearchableItems(sampleDocuments.map(Self.searchableItem))
            hasIndexedSamples = true
            answer = ""
            events = []
            matchedDocuments = []
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startRun() {
        guard canRun else { return }
        cancelRun()

        let prompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let runID = UUID()
        activeRunID = runID
        isRunning = true
        answer = ""
        errorMessage = nil
        events = []
        matchedDocuments = []

        runTask = Task { @MainActor [weak self] in
            await self?.performRun(prompt: prompt, id: runID)
        }
    }

    func cancelRun() {
        activeRunID = nil
        runTask?.cancel()
        runTask = nil
        isRunning = false
    }

    func reset() {
        cancelRun()
        prompt = Self.defaultPrompt
        answer = ""
        errorMessage = nil
        events = []
        matchedDocuments = []
        guidance = .dynamic
        usesCompactFormat = true
    }

    func clearIndex() async {
        cancelRun()
        isIndexing = true
        errorMessage = nil

        defer { isIndexing = false }

        do {
            try await CSSearchableIndex.default().deleteSearchableItems(
                withDomainIdentifiers: [Self.domainIdentifier]
            )
            hasIndexedSamples = false
            answer = ""
            events = []
            matchedDocuments = []
        } catch is CancellationError {
            return
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension SpotlightRAGViewModel {
    func performRun(prompt: String, id: UUID) async {
        defer {
            if activeRunID == id {
                activeRunID = nil
                runTask = nil
                isRunning = false
            }
        }

        guard SystemLanguageModel.default.isAvailable else {
            errorMessage = String(localized: "The on-device system language model is unavailable.")
            return
        }

        let tool = makeTool()
        let monitor = Task { @MainActor [weak self] in
            await self?.monitor(tool: tool, runID: id)
        }
        defer { monitor.cancel() }

        do {
            let session = LanguageModelSession(
                tools: [tool],
                instructions: """
                Answer questions using the app's Spotlight index. Cite the titles of the indexed items you rely on. If the index \
                doesn't contain enough evidence, say that plainly instead of guessing.
                """
            )
            let response = try await session.respond(to: prompt)
            try Task.checkCancellation()
            guard activeRunID == id else { return }
            answer = response.content
        } catch is CancellationError {
            return
        } catch {
            guard activeRunID == id else { return }
            errorMessage = error.localizedDescription
        }
    }

    func makeTool() -> SpotlightSearchTool {
        let attributes: [SearchableItemAttribute] = [
            .title,
            .textContent,
            .contentDescription,
            .keywords,
            .contentModificationDate
        ]
        var source = CoreSpotlightSource(fetchAttributes: attributes)
        source.maximumResultCount = 8

        let level: SpotlightSearchTool.GuidanceLevel
        switch guidance {
        case .focused:
            level = .focused(.items)
        case .dynamic:
            level = .dynamic(
                .init(
                    textMatch: true,
                    similarityMatch: true,
                    numericMatch: false,
                    dates: true,
                    people: false,
                    contentType: true,
                    attributes: attributes
                )
            )
        case .complete:
            level = .complete
        }

        let guide = SpotlightSearchTool.Guide(
            level: level,
            format: usesCompactFormat ? .compact : .structured
        )
        return SpotlightSearchTool(
            configuration: .init(
                sources: [.coreSpotlight(source)],
                guide: guide
            )
        )
    }

    func monitor(tool: SpotlightSearchTool, runID: UUID) async {
        var queryNumbers: [SpotlightSearchTool.SearchReply.QueryToken: Int] = [:]

        for await reply in tool.searchResults {
            guard !Task.isCancelled, activeRunID == runID else { return }
            let queryNumber: Int
            if let existing = queryNumbers[reply.queryToken] {
                queryNumber = existing
            } else {
                queryNumber = queryNumbers.count + 1
                queryNumbers[reply.queryToken] = queryNumber
            }

            let event = makeEvent(from: reply, queryNumber: queryNumber)
            events.append(event)
        }
    }

    func makeEvent(
        from reply: SpotlightSearchTool.SearchReply,
        queryNumber: Int
    ) -> SpotlightRAGSearchEvent {
        let statusIsComplete = reply.status == .complete
        let label = reply.label ?? String(localized: "Search stage")

        switch reply.content {
        case .items(let items):
            capture(items)
            return event(queryNumber, label, itemSummary(items), .items, statusIsComplete)
        case .scoredItems(let scoredItems):
            return scoredEvent(scoredItems, queryNumber, label, statusIsComplete)
        case .groupedItems(let groups):
            return groupedEvent(groups, queryNumber, label, statusIsComplete)
        case .count(let count):
            return event(
                queryNumber,
                count.header ?? label,
                String(localized: "\(count.value) results"),
                .count,
                statusIsComplete
            )
        case .table(let table):
            return event(
                queryNumber,
                table.header ?? label,
                String(localized: "\(table.rows.count) rows · \(table.columns.count) columns"),
                .table,
                statusIsComplete
            )
        case .statistic(let statistic):
            return event(
                queryNumber,
                statistic.header ?? label,
                String(localized: "\(statistic.name): \(statistic.value.formatted())"),
                .statistic,
                statusIsComplete
            )
        case .text(let text):
            return event(queryNumber, text.header ?? label, text.body, .text, statusIsComplete)
        @unknown default:
            return event(
                queryNumber,
                label,
                String(localized: "A newer Spotlight result type was returned."),
                .text,
                statusIsComplete
            )
        }
    }

    func scoredEvent(
        _ scoredItems: [ScoredSearchableItem],
        _ queryNumber: Int,
        _ label: String,
        _ isComplete: Bool
    ) -> SpotlightRAGSearchEvent {
        let items = scoredItems.map(\.item)
        capture(items)
        let scoreDetail = scoredItems.map(\.score).max().map {
            String(localized: "Top score: \($0.formatted(.number.precision(.fractionLength(2))))")
        }
        return event(
            queryNumber,
            label,
            [itemSummary(items), scoreDetail].compactMap(\.self).joined(separator: " · "),
            .scoredItems,
            isComplete
        )
    }

    func groupedEvent(
        _ groups: [SearchableItemAttribute: [CSSearchableItem]],
        _ queryNumber: Int,
        _ label: String,
        _ isComplete: Bool
    ) -> SpotlightRAGSearchEvent {
        let items = groups.values.flatMap(\.self)
        capture(items)
        return event(
            queryNumber,
            label,
            String(localized: "\(groups.count) groups · \(items.count) items"),
            .groupedItems,
            isComplete
        )
    }

    func event(
        _ queryNumber: Int,
        _ label: String,
        _ detail: String,
        _ kind: SpotlightRAGSearchEvent.Kind,
        _ isComplete: Bool
    ) -> SpotlightRAGSearchEvent {
        SpotlightRAGSearchEvent(
            queryNumber: queryNumber,
            label: label,
            detail: detail,
            kind: kind,
            isComplete: isComplete
        )
    }

    func capture(_ items: [CSSearchableItem]) {
        let existingIDs = Set(matchedDocuments.map(\.id))
        let additions = items.compactMap(Self.document).filter { !existingIDs.contains($0.id) }
        matchedDocuments.append(contentsOf: additions)
    }

    func itemSummary(_ items: [CSSearchableItem]) -> String {
        let titles = items.compactMap(\.attributeSet.title)
        guard !titles.isEmpty else { return String(localized: "\(items.count) items") }
        return titles.joined(separator: ", ")
    }

    static func searchableItem(for document: SpotlightRAGDocument) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = document.title
        attributes.textContent = document.body
        attributes.contentDescription = document.body
        attributes.keywords = document.keywords
        attributes.contentModificationDate = document.modifiedAt
        attributes.userCreated = true
        attributes.userOwned = true

        return CSSearchableItem(
            uniqueIdentifier: document.id,
            domainIdentifier: domainIdentifier,
            attributeSet: attributes
        )
    }

    static func document(from item: CSSearchableItem) -> SpotlightRAGDocument? {
        guard let title = item.attributeSet.title else { return nil }
        return SpotlightRAGDocument(
            id: item.uniqueIdentifier,
            title: title,
            body: item.attributeSet.textContent ?? item.attributeSet.contentDescription ?? "",
            keywords: item.attributeSet.keywords ?? [],
            modifiedAt: item.attributeSet.contentModificationDate ?? .distantPast
        )
    }
}
#endif
