//
//  ContextBudgetSimulation.swift
//  FoundationLab
//

import Foundation
import FoundationModels

struct ContextBudgetSimulation {
    struct Entry: Identifiable {
        enum Disposition {
            case kept
            case summarized
            case dropped

            var title: String {
                switch self {
                case .kept: "Kept"
                case .summarized: "Summary"
                case .dropped: "Dropped"
                }
            }

            var systemImage: String {
                switch self {
                case .kept: "checkmark.circle.fill"
                case .summarized: "text.badge.checkmark"
                case .dropped: "minus.circle"
                }
            }
        }

        let id: String
        let title: String
        let kind: String
        let originalTokens: Int?
        let resultingTokens: Int?
        let disposition: Disposition
    }

    struct SourceEntry: Identifiable {
        let id: String
        let title: String
        let kind: String
        let transcriptEntry: Transcript.Entry
    }

    let contextSize: Int
    let promptTokens: Int?
    let historyTokenCounts: [String: Int]?
    let responseReserve: Int
    let policy: ContextBudgetPolicy

    static let sampleEntries: [SourceEntry] = [
        SourceEntry(
            id: "instructions",
            title: "System instructions",
            kind: "Instructions",
            transcriptEntry: .instructions(
                Transcript.Instructions(
                    segments: [.text(Transcript.TextSegment(content: longInstructions))],
                    toolDefinitions: []
                )
            )
        ),
        SourceEntry(
            id: "old-plan",
            title: "Early architecture discussion",
            kind: "Prompt",
            transcriptEntry: .prompt(
                Transcript.Prompt(segments: [.text(Transcript.TextSegment(content: earlyArchitecturePrompt))])
            )
        ),
        SourceEntry(
            id: "draft",
            title: "Discarded implementation draft",
            kind: "Response",
            transcriptEntry: .response(
                Transcript.Response(
                    assetIDs: [],
                    segments: [.text(Transcript.TextSegment(content: discardedDraft))]
                )
            )
        ),
        SourceEntry(
            id: "tools",
            title: "Completed research output",
            kind: "Tool output",
            transcriptEntry: .toolOutput(
                Transcript.ToolOutput(
                    id: "sample-research",
                    toolName: "documentationSearch",
                    segments: [.text(Transcript.TextSegment(content: researchOutput))]
                )
            )
        ),
        SourceEntry(
            id: "latest",
            title: "Latest decision and constraints",
            kind: "Prompt",
            transcriptEntry: .prompt(
                Transcript.Prompt(segments: [.text(Transcript.TextSegment(content: latestConstraints))])
            )
        )
    ]

    static let summaryEntry = SourceEntry(
        id: "summary",
        title: "Summary of earlier conversation",
        kind: "App-generated prompt context",
        transcriptEntry: .prompt(
            Transcript.Prompt(segments: [.text(Transcript.TextSegment(content: compactedSummary))])
        )
    )

    static var entriesToMeasure: [SourceEntry] {
        sampleEntries + [summaryEntry]
    }

    private var sourceEntries: [Entry] {
        Self.sampleEntries.map { source in
            let tokens = historyTokenCounts?[source.id]
            return Entry(
                id: source.id,
                title: source.title,
                kind: source.kind,
                originalTokens: tokens,
                resultingTokens: tokens,
                disposition: .kept
            )
        }
    }

    var processedEntries: [Entry] {
        switch policy {
        case .preserveAll:
            sourceEntries
        case .keepRecent:
            sourceEntries.map { entry in
                guard entry.id == "instructions" || entry.id == "tools" || entry.id == "latest" else {
                    return Entry(
                        id: entry.id,
                        title: entry.title,
                        kind: entry.kind,
                        originalTokens: entry.originalTokens,
                        resultingTokens: entry.originalTokens == nil ? nil : 0,
                        disposition: .dropped
                    )
                }
                return entry
            }
        case .summarizeEarlier:
            [
                sourceEntries[0],
                Entry(
                    id: Self.summaryEntry.id,
                    title: Self.summaryEntry.title,
                    kind: Self.summaryEntry.kind,
                    originalTokens: combinedEarlierTokens,
                    resultingTokens: historyTokenCounts?[Self.summaryEntry.id],
                    disposition: .summarized
                ),
                sourceEntries[4]
            ]
        }
    }

    var historyTokensBeforePolicy: Int? {
        sum(sourceEntries.map(\.originalTokens))
    }

    var historyTokensAfterPolicy: Int? {
        sum(processedEntries.map(\.resultingTokens))
    }

    var totalBeforePolicy: Int? {
        guard let historyTokensBeforePolicy, let promptTokens else { return nil }
        return historyTokensBeforePolicy + promptTokens + responseReserve
    }

    var totalAfterPolicy: Int? {
        guard let historyTokensAfterPolicy, let promptTokens else { return nil }
        return historyTokensAfterPolicy + promptTokens + responseReserve
    }

    var budgetEquation: String {
        guard let historyTokensAfterPolicy, let promptTokens else {
            return "Waiting for tokenizer"
        }
        return "\(historyTokensAfterPolicy) history + \(promptTokens) prompt + \(responseReserve) response"
    }

    var fitsAfterPolicy: Bool? {
        totalAfterPolicy.map { $0 <= contextSize }
    }

    var outcomeTitle: String {
        guard let totalAfterPolicy else { return "Not measured" }
        let difference = contextSize - totalAfterPolicy
        return difference >= 0 ? "Fits with \(difference) tokens free" : "Over by \(-difference) tokens"
    }

    var outcomeIcon: String {
        guard let fitsAfterPolicy else { return "ruler" }
        return fitsAfterPolicy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    var recommendation: String {
        guard let fitsAfterPolicy else {
            return "Measure the prompt and sample transcript before comparing policies."
        }
        if fitsAfterPolicy {
            return "Create the next LanguageModelSession with the prepared transcript, then send the prompt with the response limit."
        }
        if policy == .preserveAll {
            return "This request can trigger exceededContextWindowSize. Choose an app policy that reduces history before calling respond."
        }
        return "Reduce the response reserve, compact more history, or start a fresh session."
    }

    private var combinedEarlierTokens: Int? {
        sum([historyTokenCounts?["old-plan"], historyTokenCounts?["draft"], historyTokenCounts?["tools"]])
    }

    private func sum(_ values: [Int?]) -> Int? {
        guard values.allSatisfy({ $0 != nil }) else { return nil }
        return values.compactMap { $0 }.reduce(0, +)
    }
}

private let longInstructions = String(
    repeating: "Be precise, preserve user constraints, cite the relevant framework behavior, and avoid inventing APIs. ",
    count: 24
)

private let earlyArchitecturePrompt = String(
    repeating: "Compare the session architecture, transcript lifecycle, tool definitions, and structured-generation requirements. ",
    count: 34
)

private let discardedDraft = String(
    repeating: "The first implementation explored several alternatives, recorded tradeoffs, and included code that was later rejected. ",
    count: 42
)

private let researchOutput = String(
    repeating: "Apple documentation confirms the model context, transcript entry, token counting, and response option behavior. ",
    count: 48
)

private let latestConstraints = String(
    repeating: "Keep the interface native, truthful, accessible, and focused on the exact behavior a developer controls. ",
    count: 26
)

private let compactedSummary = """
The user needs a native and truthful Foundation Models example. Preserve the latest constraints and use official APIs. Clearly separate
framework behavior from app-owned transcript policy. Earlier alternatives were rejected.
"""
