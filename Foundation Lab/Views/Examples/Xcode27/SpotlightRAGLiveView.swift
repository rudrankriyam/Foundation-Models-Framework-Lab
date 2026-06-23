//
//  SpotlightRAGLiveView.swift
//  FoundationLab
//

#if compiler(>=6.4) && arch(arm64)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SpotlightRAGLiveView: View {
    @State private var model = SpotlightRAGViewModel()

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.large) {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("Live retrieval experiment")
                            .bold()
                        Text(
                            """
                            Index local sample notes, inspect every Spotlight search stage, and compare the evidence with the \
                            model's answer.
                            """
                        )
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "sparkle.magnifyingglass")
                        .foregroundStyle(.blue)
                }
                .font(.callout)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.blue.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))

                SpotlightRAGIndexSection(model: model)
                SpotlightRAGConfigurationSection(model: model)

                Xcode27Section(String(localized: "Ask the Index")) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        TextField("Ask about the indexed notes", text: $model.prompt, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityHint("The model searches only the sample notes indexed by this lab")

                        PromptSuggestions(
                            suggestions: [
                                String(localized: "What did I decide about Kyoto?"),
                                String(localized: "How should I validate a Foundation Lab release?"),
                                String(localized: "Which hike advice mentions rain?"),
                                String(localized: "What does the index not know about Tokyo?")
                            ],
                            onSelect: selectPrompt
                        )

                        HStack(spacing: Spacing.small) {
                            Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                                .buttonStyle(.glass)
                                .frame(maxWidth: .infinity)

                            Button(
                                model.isRunning ? "Stop" : "Search and Answer",
                                systemImage: model.isRunning ? "stop.fill" : "sparkle.magnifyingglass",
                                action: toggleRun
                            )
                            .buttonStyle(.glassProminent)
                            .frame(maxWidth: .infinity)
                            .disabled(!model.isRunning && !model.canRun)
                        }
                        .controlSize(.large)
                    }
                }

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
                }

                SpotlightRAGResultsSection(model: model)
                CodeDisclosure(code: codeExample)
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .navigationTitle("Spotlight RAG")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Ground answers in your app's indexed content")
        #endif
        .onDisappear(perform: model.cancelRun)
        .sensoryFeedback(.success, trigger: model.hasIndexedSamples)
    }

    private func selectPrompt(_ prompt: String) {
        model.prompt = prompt
    }

    private func toggleRun() {
        if model.isRunning {
            model.cancelRun()
        } else {
            model.startRun()
        }
    }

    private var codeExample: String {
        """
        import CoreSpotlight
        import FoundationModels

        let attributes: [SearchableItemAttribute] = [
            .title, .textContent, .contentDescription, .keywords
        ]
        let source = CoreSpotlightSource(fetchAttributes: attributes)
        let guide = SpotlightSearchTool.Guide(
            level: .dynamic(.init(
                textMatch: true,
                similarityMatch: true,
                attributes: attributes
            )),
            format: .compact
        )
        let tool = SpotlightSearchTool(configuration: .init(
            sources: [.coreSpotlight(source)],
            guide: guide
        ))

        Task {
            for await reply in tool.searchResults {
                inspect(reply.content)
            }
        }

        let session = LanguageModelSession(tools: [tool])
        let response = try await session.respond(to: prompt)
        """
    }
}
#endif
