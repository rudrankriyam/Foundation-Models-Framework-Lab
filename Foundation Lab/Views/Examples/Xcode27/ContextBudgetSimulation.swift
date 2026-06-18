//
//  ContextBudgetSimulation.swift
//  FoundationLab
//

import Foundation

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
        let originalTokens: Int
        let resultingTokens: Int
        let disposition: Disposition
    }

    let contextSize: Int
    let promptTokens: Int
    let responseReserve: Int
    let policy: ContextBudgetPolicy

    private let sourceEntries = [
        Entry(
            id: "instructions", title: "System instructions", kind: "Instructions",
            originalTokens: 360, resultingTokens: 360, disposition: .kept
        ),
        Entry(
            id: "old-plan", title: "Early architecture discussion", kind: "Prompt + response",
            originalTokens: 780, resultingTokens: 780, disposition: .kept
        ),
        Entry(
            id: "draft", title: "Discarded implementation draft", kind: "Prompt + response",
            originalTokens: 920, resultingTokens: 920, disposition: .kept
        ),
        Entry(
            id: "tools", title: "Completed research tool output", kind: "Tool calls + output",
            originalTokens: 1_100, resultingTokens: 1_100, disposition: .kept
        ),
        Entry(
            id: "latest", title: "Latest decision and constraints", kind: "Prompt + response",
            originalTokens: 620, resultingTokens: 620, disposition: .kept
        )
    ]

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
                        resultingTokens: 0,
                        disposition: .dropped
                    )
                }
                return entry
            }
        case .summarizeEarlier:
            [
                sourceEntries[0],
                Entry(
                    id: "summary",
                    title: "Summary of earlier conversation",
                    kind: "App-generated prompt context",
                    originalTokens: sourceEntries[1...3].map(\.originalTokens).reduce(0, +),
                    resultingTokens: 320,
                    disposition: .summarized
                ),
                sourceEntries[4]
            ]
        }
    }

    var historyTokensBeforePolicy: Int {
        sourceEntries.map(\.originalTokens).reduce(0, +)
    }

    var historyTokensAfterPolicy: Int {
        processedEntries.map(\.resultingTokens).reduce(0, +)
    }

    var totalBeforePolicy: Int {
        historyTokensBeforePolicy + promptTokens + responseReserve
    }

    var totalAfterPolicy: Int {
        historyTokensAfterPolicy + promptTokens + responseReserve
    }

    var budgetEquation: String {
        "\(historyTokensAfterPolicy) history + \(promptTokens) prompt + \(responseReserve) response"
    }

    var fitsAfterPolicy: Bool {
        totalAfterPolicy <= contextSize
    }

    var remainingTokens: Int {
        max(0, contextSize - totalAfterPolicy)
    }

    var outcomeTitle: String {
        fitsAfterPolicy ? "Fits with \(remainingTokens) tokens free" : "Over by \(totalAfterPolicy - contextSize) tokens"
    }

    var outcomeIcon: String {
        fitsAfterPolicy ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    var recommendation: String {
        if fitsAfterPolicy {
            "Create the next LanguageModelSession with the prepared transcript, then send the prompt with the response limit."
        } else if policy == .preserveAll {
            "This request can trigger exceededContextWindowSize. Choose an app policy that reduces history before calling respond."
        } else {
            "The selected policy still leaves too little room. Reduce the response reserve, compact more history, or start a fresh session."
        }
    }
}
