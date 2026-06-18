//
//  SpotlightRAGExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct SpotlightRAGExplorerView: View {
    @State private var currentPrompt = "What did I decide about the Kyoto itinerary?"
    @State private var selectedStage = SpotlightRAGStage.search

    var body: some View {
        ExampleViewBase(
            title: "Spotlight RAG",
            description: "Explain search-grounded Foundation Models answers",
            defaultPrompt: "What did I decide about the Kyoto itinerary?",
            currentPrompt: $currentPrompt,
            codeExample: selectedStage.code,
            onRun: nextStage,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Pipeline") {
                    VStack(spacing: 0) {
                        ForEach(SpotlightRAGStage.allCases) { stage in
                            Button {
                                select(stage)
                            } label: {
                                HStack {
                                    Xcode27InfoRow(
                                        title: stage.title,
                                        detail: stage.detail,
                                        systemImage: stage.icon,
                                        tint: stage == selectedStage ? .blue : .secondary
                                    )

                                    if stage == selectedStage {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.blue)
                                            .accessibilityHidden(true)
                                    }
                                }
                                .frame(minHeight: 44)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(stage == selectedStage ? .isSelected : [])

                            if stage != SpotlightRAGStage.allCases.last {
                                Divider()
                            }
                        }
                    }
                }

                Xcode27Section(selectedStage.title) {
                    Text(selectedStage.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func nextStage() {
        let cases = SpotlightRAGStage.allCases
        guard let index = cases.firstIndex(of: selectedStage) else { return }
        selectedStage = cases[(index + 1) % cases.count]
    }

    private func select(_ stage: SpotlightRAGStage) {
        selectedStage = stage
    }

    private func reset() {
        currentPrompt = ""
        selectedStage = .search
    }
}

private enum SpotlightRAGStage: String, CaseIterable, Identifiable {
    case search
    case hydrate
    case guide
    case answer
    case evaluate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .search: return "Search"
        case .hydrate: return "Hydrate"
        case .guide: return "Guide"
        case .answer: return "Answer"
        case .evaluate: return "Evaluate"
        }
    }

    var detail: String {
        switch self {
        case .search: return "Use SpotlightSearchTool against indexed app content."
        case .hydrate: return "Fetch complete objects for selected results."
        case .guide: return "Constrain attributes and date/person matching."
        case .answer: return "Respond with grounded source references."
        case .evaluate: return "Check trajectory and answer quality."
        }
    }

    var explanation: String {
        switch self {
        case .search:
            return "Search should return enough candidates to ground the answer without stuffing the whole index into context."
        case .hydrate:
            return "Hydration lets the model start with compact search hits, then request full data only when needed."
        case .guide:
            return "Guidance profiles teach the search tool which attributes matter for a task, such as dates, titles, or people."
        case .answer:
            return "The answer should name the source or explain when the index did not contain enough evidence."
        case .evaluate:
            return """
            Evaluate both result relevance and the tool-call path. A good answer with the wrong trajectory can still hide a fragile flow.
            """
        }
    }

    var icon: String {
        switch self {
        case .search: return "magnifyingglass"
        case .hydrate: return "tray.and.arrow.down"
        case .guide: return "slider.horizontal.3"
        case .answer: return "quote.bubble"
        case .evaluate: return "checklist.checked"
        }
    }

    var code: String {
        """
        import CoreSpotlight
        import FoundationModels

        let tool = SpotlightSearchTool(
            configuration: .init(
                guide: .init(level: .dynamic(profile))
            )
        )
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            tools: [tool],
            instructions: instructions
        )
        """
    }
}

#Preview {
    NavigationStack {
        SpotlightRAGExplorerView()
    }
}
