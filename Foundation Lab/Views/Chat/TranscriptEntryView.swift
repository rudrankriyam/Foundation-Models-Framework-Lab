//
//  TranscriptEntryView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModels
import FoundationModelsKit

struct TranscriptEntryView: View {
    let entry: Transcript.Entry
    let transcriptIndex: Int
    @State private var tokenCount: Int?
    @Environment(ChatViewModel.self) private var chatViewModel

    var body: some View {
        VStack(spacing: 2) {
            entryContent

            if let tokenCount {
                Text("^[\(tokenCount) token](inflect: true)")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(
                        maxWidth: .infinity,
                        alignment: entry.isFromUser ? .trailing : .leading
                    )
                    .padding(.horizontal, Spacing.large)
            }
        }
        .task(id: "\(transcriptIndex)-\(entry.id)") {
            tokenCount = nil
            tokenCount = await resolveTokenCount()
        }
    }

    @ViewBuilder
    private var entryContent: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = prompt.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(content: text, isFromUser: true))
            }

        case .response(let response):
            if let text = response.segments.textContentJoined() {
                MessageBubbleView(message: ChatMessage(entryID: entry.id, content: text, isFromUser: false))
            }

        case .toolCalls(let toolCalls):
            ForEach(toolCalls.enumerated(), id: \.offset) { _, toolCall in
                TranscriptToolEventView(
                    kind: .call,
                    toolName: toolCall.toolName,
                    detail: toolCall.arguments.jsonString
                )
            }

        case .toolOutput(let toolOutput):
            if let text = toolOutput.segments.textContentJoined() {
                TranscriptToolEventView(
                    kind: .result,
                    toolName: toolOutput.toolName,
                    detail: text
                )
            }

        #if compiler(>=6.4)
        case .reasoning(let reasoning):
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                ReasoningTraceView(reasoning: reasoning)
            }
        #endif

        case .instructions:
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }

    private func resolveTokenCount() async -> Int? {
        if case .instructions = entry {
            return nil
        }

        // Avoid repeatedly calling the tokenizer while the newest entry is still streaming.
        if chatViewModel.session.isResponding,
           chatViewModel.session.transcript.indices.last == transcriptIndex {
            await waitForStreamingToFinish()
        }

        // Always compute tokens from the latest version of the entry in the transcript.
        let latestEntry = chatViewModel.session.transcript.indices.contains(transcriptIndex)
            ? chatViewModel.session.transcript[transcriptIndex]
            : entry
        return await tokenCount(for: latestEntry)
    }

    private func waitForStreamingToFinish() async {
        while chatViewModel.session.isResponding, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(150))
        }

        // Give the transcript a moment to publish its final segment.
        try? await Task.sleep(for: .milliseconds(50))
    }

    private func tokenCount(for entry: Transcript.Entry) async -> Int? {
        await entry.tokenCount()
    }
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
private struct ReasoningTraceView: View {
    let reasoning: Transcript.Reasoning

    @State private var isExpanded = true

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(traceText)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .padding(.bottom, Spacing.small)
        } label: {
            HStack(spacing: Spacing.small) {
                Label("Reasoning Trace", systemImage: "brain.head.profile")
                    .font(.subheadline)

                Spacer(minLength: Spacing.small)

                if reasoning.signature != nil {
                    Text("Signed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(minHeight: 44)
        }
        .tint(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.large)
        .accessibilityHint("Shows the model's reasoning trace")
    }

    private var traceText: String {
        if let text = reasoning.segments.textContentJoined() {
            return text
        }

        if reasoning.signature != nil {
            return String(localized: "The model provided an opaque reasoning signature, but no readable reasoning text.")
        }

        return String(localized: "No readable reasoning trace was included in this transcript entry.")
    }
}
#endif

private extension Transcript.Entry {
    var isFromUser: Bool {
        if case .prompt = self { return true }
        return false
    }
}
