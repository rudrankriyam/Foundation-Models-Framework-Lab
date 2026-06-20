//
//  SpotlightRAGExplorerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct SpotlightRAGExplorerView: View {
    @State private var selectedStage = SpotlightRAGStage.index

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("Architecture walkthrough")
                            .bold()
                        Text(
                            String(
                                localized: """
                                This screen does not query Spotlight or a language model. It explains how SpotlightSearchTool grounds \
                                a real session in content your app has indexed.
                                """
                            )
                        )
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "book.pages")
                        .foregroundStyle(.blue)
                }
                .font(.callout)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))

                Xcode27Section(String(localized: "Example Question")) {
                    Text("“What did I decide about the Kyoto itinerary?”")
                        .font(.callout)
                        .textSelection(.enabled)
                }

                Xcode27Section(String(localized: "Pipeline")) {
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
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedStage.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Button("Inspect Next Stage", systemImage: "arrow.down", action: nextStage)
                            .buttonStyle(.glassProminent)
                    }
                }

                CodeDisclosure(code: selectedStage.code)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Spotlight RAG")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Ground a session in your app's indexed content")
        #endif
    }

    private func nextStage() {
        let cases = SpotlightRAGStage.allCases
        guard let index = cases.firstIndex(of: selectedStage) else { return }
        selectedStage = cases[(index + 1) % cases.count]
    }

    private func select(_ stage: SpotlightRAGStage) {
        selectedStage = stage
    }
}

private enum SpotlightRAGStage: String, CaseIterable, Identifiable {
    case index
    case tool
    case prompt
    case evaluate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .index: return String(localized: "Index Content")
        case .tool: return String(localized: "Add Search Tool")
        case .prompt: return String(localized: "Prompt Session")
        case .evaluate: return String(localized: "Evaluate")
        }
    }

    var detail: String {
        switch self {
        case .index: return String(localized: "Maintain a Core Spotlight index for your app's content.")
        case .tool: return String(localized: "Make that index available to LanguageModelSession.")
        case .prompt: return String(localized: "Ask a question that requires indexed knowledge.")
        case .evaluate: return String(localized: "Test retrieval relevance and answer quality.")
        }
    }

    var explanation: String {
        switch self {
        case .index:
            return String(
                localized: """
                SpotlightSearchTool searches content already indexed by your app. Index useful metadata and keep the index \
                synchronized as content changes.
                """
            )
        case .tool:
            return String(
                localized: """
                Add SpotlightSearchTool to the tools passed to LanguageModelSession. The model can then search the local index when a \
                prompt requires app-specific knowledge.
                """
            )
        case .prompt:
            return String(
                localized: """
                Call respond on the session as usual. Tool calling lets the model retrieve relevant indexed content and use it as \
                additional context for the answer.
                """
            )
        case .evaluate:
            return String(
                localized: """
                Use representative questions and verify retrieval relevance, honest handling of missing evidence, and answers that \
                stay grounded in the index.
                """
            )
        }
    }

    var icon: String {
        switch self {
        case .index: return "square.stack.3d.up"
        case .tool: return "wrench.and.screwdriver"
        case .prompt: return "text.bubble"
        case .evaluate: return "checklist.checked"
        }
    }

    var code: String {
        switch self {
        case .index:
            return """
            import CoreSpotlight
            import UniformTypeIdentifiers

            let attributes = CSSearchableItemAttributeSet(contentType: .text)
            attributes.title = "Kyoto itinerary"
            attributes.contentDescription = "Dinner in Gion on Friday."

            let item = CSSearchableItem(
                uniqueIdentifier: "trip.kyoto",
                domainIdentifier: "travel",
                attributeSet: attributes
            )
            try await CSSearchableIndex.default().indexSearchableItems([item])
            """
        case .tool, .prompt:
            return """
            import CoreSpotlight
            import FoundationModels

            let tool = SpotlightSearchTool()
            let session = LanguageModelSession(tools: [tool])
            let response = try await session.respond(
                to: "What did I decide about the Kyoto itinerary?"
            )
            """
        case .evaluate:
            return """
            // Exercise questions with relevant, missing, and ambiguous evidence.
            // Inspect retrieval and final-answer quality with Instruments
            // and your evaluation suite.
            """
        }
    }
}

#Preview {
    NavigationStack {
        SpotlightRAGExplorerView()
    }
}
