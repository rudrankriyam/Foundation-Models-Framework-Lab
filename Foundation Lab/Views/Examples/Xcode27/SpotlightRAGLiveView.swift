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
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Ask your Spotlight index")
                        .font(.title2.bold())
                    Text("Index four notes, ask one question, then inspect the evidence behind the answer.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SpotlightRAGIndexSection(model: model)
                SpotlightRAGConfigurationSection(model: model)

                Xcode27Section(String(localized: "Ask the Index")) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        TextField("Ask about the indexed notes", text: $model.prompt, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityHint("The model searches only the sample notes indexed by this lab")

                        HStack {
                            Menu("Example Questions", systemImage: "text.bubble") {
                                ForEach(examplePrompts, id: \.self) { prompt in
                                    Button(prompt) { selectPrompt(prompt) }
                                }
                            }
                            .padding(.vertical, Spacing.medium)
                            .contentShape(.rect)

                            Spacer()

                            Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                                .buttonStyle(.borderless)
                                .padding(.vertical, Spacing.medium)
                                .contentShape(.rect)
                        }

                        Button(
                            model.isRunning ? "Stop" : "Search Spotlight and Answer",
                            systemImage: model.isRunning ? "stop.fill" : "sparkle.magnifyingglass",
                            action: toggleRun
                        )
                        .buttonStyle(.glassProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(!model.isRunning && !model.canRun)
                        .controlSize(.large)
                    }
                }

                if let errorMessage = model.errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.callout)
                }

                SpotlightRAGResultsSection(model: model)
                CodeDisclosure(code: codeExample)
            }
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
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
        .sensoryFeedback(.success, trigger: model.hasIndexedSamples) { _, isReady in
            isReady
        }
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

    private var examplePrompts: [String] {
        [
            String(localized: "What did I decide about Kyoto?"),
            String(localized: "How should I validate a Foundation Lab release?"),
            String(localized: "Which hike advice mentions rain?"),
            String(localized: "What does the index not know about Tokyo?")
        ]
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
            level: .focused(.items),
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

        // Require retrieval once, then switch to allowed so the model can answer.
        let session = LanguageModelSession(profile: SpotlightRAGProfile(tool: tool))
        let response = try await session.respond(to: prompt)
        """
    }
}
#endif
