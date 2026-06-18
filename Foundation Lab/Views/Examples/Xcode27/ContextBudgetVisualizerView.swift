//
//  ContextBudgetVisualizerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ContextBudgetVisualizerView: View {
    @State private var currentPrompt = "Visualize which transcript entries survive compaction."
    @State private var strategy = BudgetStrategy.balanced

    private var entries: [BudgetEntry] {
        BudgetEntry.samples.map { entry in entry.applying(strategy) }
    }

    private var keptTokens: Int {
        entries.filter { $0.state != .dropped }.map(\.displayTokens).reduce(0, +)
    }

    var body: some View {
        ExampleViewBase(
            title: "Budget Visualizer",
            description: "See what gets kept, summarized, or dropped",
            defaultPrompt: "Visualize which transcript entries survive compaction.",
            currentPrompt: $currentPrompt,
            codeExample: strategy.code,
            onRun: cycleStrategy,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Strategy", selection: $strategy) {
                    ForEach(BudgetStrategy.allCases) { strategy in
                        Text(strategy.title).tag(strategy)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27StatusRow(
                    title: "Compacted Prompt",
                    value: "\(keptTokens) tokens kept",
                    systemImage: "chart.pie",
                    tint: strategy.tint
                )

                Xcode27Section("Transcript Entries") {
                    VStack(spacing: 0) {
                        ForEach(entries) { entry in
                            BudgetEntryRow(entry: entry)

                            if entry.id != entries.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func cycleStrategy() {
        let cases = BudgetStrategy.allCases
        guard let index = cases.firstIndex(of: strategy) else { return }
        strategy = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        strategy = .balanced
    }
}

private struct BudgetEntryRow: View {
    let entry: BudgetEntry

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: entry.state.icon)
                .foregroundStyle(entry.state.tint)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(entry.title)
                    .font(.subheadline)
                    .bold()
                Text(entry.state.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(entry.displayTokens) tokens")
                .font(.footnote.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

private struct BudgetEntry: Identifiable {
    let id = UUID()
    let title: String
    let originalTokens: Int
    let priority: Int
    var state: BudgetEntryState = .kept

    var displayTokens: Int {
        switch state {
        case .kept: return originalTokens
        case .summarized: return max(80, originalTokens / 5)
        case .dropped: return 0
        }
    }

    func applying(_ strategy: BudgetStrategy) -> BudgetEntry {
        var copy = self
        switch strategy {
        case .lossless:
            copy.state = .kept
        case .balanced:
            copy.state = priority >= 4 ? .kept : priority >= 2 ? .summarized : .dropped
        case .aggressive:
            copy.state = priority >= 5 ? .kept : priority >= 3 ? .summarized : .dropped
        }
        return copy
    }

    static let samples = [
        BudgetEntry(title: "Initial instructions", originalTokens: 420, priority: 5),
        BudgetEntry(title: "User preferences", originalTokens: 680, priority: 5),
        BudgetEntry(title: "Old brainstorming", originalTokens: 1_800, priority: 2),
        BudgetEntry(title: "Tool results", originalTokens: 2_400, priority: 3),
        BudgetEntry(title: "Recent question", originalTokens: 160, priority: 5),
        BudgetEntry(title: "Stale retry loop", originalTokens: 900, priority: 1)
    ]
}

private enum BudgetEntryState {
    case kept
    case summarized
    case dropped

    var icon: String {
        switch self {
        case .kept: return "checkmark.circle"
        case .summarized: return "text.badge.checkmark"
        case .dropped: return "minus.circle"
        }
    }

    var tint: Color {
        switch self {
        case .kept: return .green
        case .summarized: return .orange
        case .dropped: return .red
        }
    }

    var description: String {
        switch self {
        case .kept: return "Kept verbatim"
        case .summarized: return "Replaced by compact memory"
        case .dropped: return "Removed before model call"
        }
    }
}

private enum BudgetStrategy: String, CaseIterable, Identifiable {
    case lossless
    case balanced
    case aggressive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lossless: return "Lossless"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        }
    }

    var tint: Color {
        switch self {
        case .lossless: return .green
        case .balanced: return .orange
        case .aggressive: return .red
        }
    }

    var code: String {
        """
        .historyTransform { entries in
            ContextBudgetManager(strategy: .\(rawValue))
                .compact(entries)
        }
        """
    }
}

#Preview {
    NavigationStack {
        ContextBudgetVisualizerView()
    }
}
