//
//  ChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationLabCore
import FoundationModels

struct ChatView: View {
    let title: LocalizedStringKey
    let showsDoneButton: Bool
    let tearsDownOnDisappear: Bool

    @State private var viewModel = ChatViewModel()
    @State private var scrollID: String?
    @State private var messageText = ""
    @State private var showInstructionsSheet = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    init(title: LocalizedStringKey = "Chat", showsDoneButton: Bool = true, tearsDownOnDisappear: Bool = true) {
        self.title = title
        self.showsDoneButton = showsDoneButton
        self.tearsDownOnDisappear = tearsDownOnDisappear
    }

    var body: some View {
        VStack(spacing: 0) {
            TokenUsageBar(
                currentTokenCount: viewModel.currentTokenCount,
                maxContextSize: viewModel.maxContextSize,
                tokenUsageFraction: viewModel.tokenUsageFraction
            )

            messagesView

            ChatInputView(
                messageText: $messageText,
                chatViewModel: viewModel,
                isTextFieldFocused: $isTextFieldFocused
            )
        }
        .environment(viewModel)
        .navigationTitle(viewModel.voiceState.isActive ? Text("Voice") : Text(title))
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            if showsDoneButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                ChatOptionsMenu(
                    viewModel: viewModel,
                    isChatEmpty: isChatEffectivelyEmpty,
                    onSelectModelRuntime: selectModelRuntime,
                    onSelectReasoningLevel: selectReasoningLevel,
                    onShowInstructions: showInstructions,
                    onClearChat: clearChat
                )
            }
        }
        .alert(
            "Error",
            isPresented: $viewModel.showError,
            actions: { Button("OK") { viewModel.dismissError() } },
            message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                } else {
                    Text("An unknown error occurred")
                }
            }
        )
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            isTextFieldFocused = true
        }
        .onDisappear {
            if tearsDownOnDisappear {
                viewModel.tearDown()
            }
        }
#if os(iOS)
        .fullScreenCover(isPresented: $showInstructionsSheet) {
            NavigationStack {
                ChatInstructionsView(
                    viewModel: $viewModel,
                    onApply: {
                        viewModel.updateInstructions(viewModel.instructions)
                        clearChat()
                    }
                )
                .navigationTitle("Instructions")
            }
        }
#else
        .sheet(isPresented: $showInstructionsSheet) {
            NavigationStack {
                ChatInstructionsView(
                    viewModel: $viewModel,
                    onApply: {
                        viewModel.updateInstructions(viewModel.instructions)
                        clearChat()
                    }
                )
                .navigationTitle("Instructions")
                .frame(minWidth: 500, minHeight: 400)
            }
        }
#endif
    }
}

// MARK: - View Components

private extension ChatView {
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.medium) {
                    if isChatEffectivelyEmpty {
                        Text("How can we help you today?")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, 48)
                    }

                    ForEach(transcriptDisplayEntries) { displayEntry in
                        TranscriptEntryView(
                            entry: displayEntry.entry,
                            transcriptIndex: displayEntry.transcriptIndex
                        )
                        .id(displayEntry.id)
                    }

                    if viewModel.isSummarizing {
                        ChatActivityView(title: "Summarizing conversation...")
                            .id("summarizing")
                    }

                    if viewModel.isApplyingWindow {
                        ChatActivityView(title: "Optimizing conversation history...")
                            .id("windowing")
                    }

                    // Empty spacer for bottom padding
                    Rectangle()
                        .fill(.clear)
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.vertical)
            }
#if os(iOS)
            .scrollDismissesKeyboard(.interactively)
#endif
            .scrollPosition(id: $scrollID, anchor: .bottom)
            .onChange(of: viewModel.session.transcript.count) { _, _ in
                if let lastEntryID = transcriptDisplayEntries.last?.id {
                    scroll(to: lastEntryID, using: proxy)
                }
            }
            .onChange(of: viewModel.isSummarizing) { _, isSummarizing in
                if isSummarizing {
                    scroll(to: "summarizing", using: proxy)
                }
            }
            .onChange(of: viewModel.isApplyingWindow) { _, isApplyingWindow in
                if isApplyingWindow {
                    scroll(to: "windowing", using: proxy)
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }

    private var transcriptDisplayEntries: [TranscriptDisplayEntry] {
        viewModel.session.transcript.enumerated().map { index, entry in
            TranscriptDisplayEntry(transcriptIndex: index, entry: entry)
        }
    }

    private var isChatEffectivelyEmpty: Bool {
        !viewModel.session.transcript.contains { entry in
            switch entry {
            case .instructions:
                return false
            default:
                return true
            }
        }
    }

    private func scroll(to id: String, using proxy: ScrollViewProxy) {
        if reduceMotion {
            proxy.scrollTo(id, anchor: .bottom)
        } else {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }

    private func clearChat() {
        messageText = ""
        scrollID = "bottom"
        viewModel.clearChat()
    }

    private func showInstructions() {
        showInstructionsSheet = true
    }

    private func selectModelRuntime(_ runtime: FoundationLabModelRuntime) {
        guard runtime != viewModel.selectedModelRuntime else { return }
        viewModel.selectModelRuntime(runtime)
        clearInputAfterConfigurationChange()
    }

    private func selectReasoningLevel(_ level: FoundationLabReasoningLevel) {
        guard level != viewModel.selectedReasoningLevel else { return }
        viewModel.selectReasoningLevel(level)
        clearInputAfterConfigurationChange()
    }

    private func clearInputAfterConfigurationChange() {
        messageText = ""
        scrollID = "bottom"
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
