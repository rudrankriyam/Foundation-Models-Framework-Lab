import FoundationLabCore
import FoundationModels
import SwiftUI

struct PlaygroundTranscriptView: View {
    let viewModel: ChatViewModel
    let configuration: FoundationLabExperimentConfiguration
    @Binding var scrollID: String?
    let runSuggestedPrompt: () -> Void
    let openLibrary: () -> Void
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if isEmpty {
                        PlaygroundEmptyState(
                            configuration: configuration,
                            runSuggestedPrompt: runSuggestedPrompt,
                            openLibrary: openLibrary
                        )
                    }

                    ForEach(transcriptEntries) { displayEntry in
                        TranscriptEntryView(
                            entry: displayEntry.entry,
                            transcriptIndex: displayEntry.transcriptIndex
                        )
                        .id(displayEntry.id)
                    }

                    if viewModel.isSummarizing {
                        ChatActivityView(title: "Summarizing conversation…")
                            .id("summarizing")
                    }

                    if viewModel.isApplyingWindow {
                        ChatActivityView(title: "Optimizing conversation history…")
                            .id("windowing")
                    }

                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .frame(maxWidth: FoundationLabLayout.transcriptContentWidth)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.large)
            }
#if os(iOS)
            .scrollDismissesKeyboard(.interactively)
#endif
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.session.transcript.count) { _, _ in
                scrollToLatest(using: proxy)
            }
        }
        .defaultScrollAnchor(.bottom)
    }

    private var transcriptEntries: [TranscriptDisplayEntry] {
        viewModel.session.transcript.enumerated().map { index, entry in
            TranscriptDisplayEntry(transcriptIndex: index, entry: entry)
        }
    }

    private var isEmpty: Bool {
        !viewModel.session.transcript.contains { entry in
            if case .instructions = entry {
                false
            } else {
                true
            }
        }
    }

    private func scrollToLatest(using proxy: ScrollViewProxy) {
        let target = transcriptEntries.last?.id ?? "bottom"

        guard !accessibilityReduceMotion else {
            proxy.scrollTo(target, anchor: .bottom)
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(target, anchor: .bottom)
        }
    }
}

private struct PlaygroundEmptyState: View {
    let configuration: FoundationLabExperimentConfiguration
    let runSuggestedPrompt: () -> Void
    let openLibrary: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Ready to Run", systemImage: configuration.kind.systemImage)
        } description: {
            Text(emptyDescription)
        } actions: {
            if configuration.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Choose an Example", systemImage: "books.vertical", action: openLibrary)
                    .buttonStyle(.borderedProminent)
            } else {
                Button("Run Suggested Prompt", systemImage: "play.fill", action: runSuggestedPrompt)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: 620, minHeight: 320)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Spacing.large)
    }

    private var emptyDescription: String {
        if configuration.summary.isEmpty {
            String(localized: "Write a prompt below or choose a ready-made experiment from the Library.")
        } else {
            configuration.summary
        }
    }
}
