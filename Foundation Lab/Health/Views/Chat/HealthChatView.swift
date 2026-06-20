//
//  HealthChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import FoundationModels
import SwiftData

struct HealthChatView: View {
    @State private var viewModel = HealthChatViewModel()
    @State private var scrollID: String?
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TokenUsageBar(
                    currentTokenCount: viewModel.currentTokenCount,
                    maxContextSize: viewModel.maxContextSize,
                    tokenUsageFraction: viewModel.tokenUsageFraction
                )
                messagesView

                HealthChatInputView(
                    messageText: $messageText,
                    chatViewModel: viewModel,
                    isTextFieldFocused: $isTextFieldFocused
                )
            }
            .background(Color.adaptiveBackground)
            .navigationTitle("Health AI")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .disabled(viewModel.session.transcript.isEmpty || viewModel.isLoading)
                }
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .task {
            await viewModel.loadInitialHealthData()
        }
        .task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            isTextFieldFocused = true
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }

    // MARK: - View Components

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    // Welcome message
                    if viewModel.session.transcript.isEmpty {
                        WelcomeMessageView(healthMetrics: viewModel.currentHealthMetrics)
                            .id("welcome")
                    }

                    ForEach(transcriptDisplayEntries, id: \.id) { displayEntry in
                        HealthTranscriptEntryView(entry: displayEntry.entry)
                            .id(displayEntry.id)
                    }

                    if viewModel.isSummarizing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Summarizing conversation...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("summarizing")
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
        }
        .defaultScrollAnchor(.bottom)
    }

    private var transcriptDisplayEntries: [(id: String, entry: Transcript.Entry)] {
        viewModel.session.transcript.enumerated().map { index, entry in
            ("\(index)-\(entry.id)", entry)
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
}

struct HealthTranscriptEntryView: View {
    let entry: Transcript.Entry

    var body: some View {
        switch entry {
        case .prompt(let prompt):
            if let text = extractText(from: prompt.segments), !text.isEmpty {
                HealthMessageBubbleView(
                    content: text,
                    isFromUser: true
                )
            }

        case .response(let response):
            if let text = extractText(from: response.segments), !text.isEmpty {
                HealthMessageBubbleView(
                    content: text,
                    isFromUser: false
                )
            }

        case .toolCalls(let toolCalls):
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { _, toolCall in
                ToolCallView(toolName: toolCall.toolName)
            }

        case .toolOutput:
            // Tool outputs are typically incorporated into the response
            EmptyView()

        #if compiler(>=6.4)
        case .reasoning:
            EmptyView()
        #endif

        case .instructions:
            // Don't show instructions in chat UI
            EmptyView()

        @unknown default:
            EmptyView()
        }
    }

    private func extractText(from segments: [Transcript.Segment]) -> String? {
        let text = segments.compactMap { segment in
            if case .text(let textSegment) = segment {
                return textSegment.content
            }
            return nil
        }.joined(separator: " ")

        return text.isEmpty ? nil : text
    }
}

struct WelcomeMessageView: View {
    let healthMetrics: [MetricType: Double]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "hand.wave.fill")
                    .font(.title2)
                    .foregroundStyle(Color.healthPrimary)

                Text("Welcome to Health AI!")
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text("Ask about health data available on this device. Answers are informational and are not medical advice.")
                .font(.body)
                .foregroundStyle(.secondary)

            if !healthMetrics.isEmpty {
                HStack(spacing: 20) {
                    if let steps = healthMetrics[.steps], steps > 0 {
                        Label("\(Int(steps)) steps", systemImage: "figure.walk")
                            .font(.caption)
                            .foregroundStyle(Color.healthPrimary)
                    }

                    if let energy = healthMetrics[.activeEnergy], energy > 0 {
                        Label("\(Int(energy)) cal", systemImage: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color.orange)
                    }
                }
            }

            Text("What would you like to understand about today's data?")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}

struct ToolCallView: View {
    let toolName: String

    var body: some View {
        HStack {
            Image(systemName: "gearshape.fill")
                .font(.caption)
                .foregroundStyle(Color.healthPrimary)

            Text("Reading your \(formatToolName(toolName))...")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Reading your \(formatToolName(toolName))")
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func formatToolName(_ name: String) -> String {
        switch name {
        case "fetchHealthData":
            return "health data"
        default:
            return "data"
        }
    }
}

#Preview {
    HealthChatView()
        .modelContainer(for: [HealthSession.self, HealthMetric.self])
}
