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
    @State private var isShowingDeleteConfirmation = false
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
            .navigationTitle("Health Chat")
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
                    Button("Delete Conversation", systemImage: "trash") {
                        isShowingDeleteConfirmation = true
                    }
                    .labelStyle(.iconOnly)
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
        .confirmationDialog(
            "Delete this conversation?",
            isPresented: $isShowingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Conversation", role: .destructive, action: viewModel.clearChat)
        } message: {
            Text("This removes the current Health chat transcript.")
        }
        .alert("Couldn’t Load Health Data", isPresented: $viewModel.showError) {
            Button("Dismiss", role: .cancel) {}
        } message: {
            Text(
                viewModel.errorMessage
                    ?? String(localized: "Health data is unavailable right now. Try again later.")
            )
        }
    }

    // MARK: - View Components

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: Spacing.large) {
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
                            Text("Summarizing conversation…")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("summarizing")
                    }

                    Rectangle()
                        .fill(.clear)
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
        VStack(alignment: .leading, spacing: Spacing.large) {
            ContentUnavailableView {
                Label("Ask About Health Data", systemImage: "heart.text.square")
            } description: {
                Text(
                    "Answers use measurements HealthKit makes available to Foundation Lab. Missing values are never estimated."
                )
            }

            if !healthMetrics.isEmpty {
                GroupBox("Available Measurements") {
                    VStack(spacing: 0) {
                        ForEach(Array(availableMetrics.enumerated()), id: \.element) { index, metric in
                            HealthMetricRow(metricType: metric, value: healthMetrics[metric])

                            if index < availableMetrics.count - 1 {
                                Divider()
                            }
                        }
                    }
                }
            }

            Label(
                "Health Chat provides informational summaries, not medical advice.",
                systemImage: "info.circle"
            )
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var availableMetrics: [MetricType] {
        [.steps, .heartRate, .sleep, .activeEnergy, .distance].filter {
            healthMetrics[$0] != nil
        }
    }
}

struct ToolCallView: View {
    let toolName: String

    var body: some View {
        Label("Reading \(formatToolName(toolName))…", systemImage: "heart.text.square")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            String(localized: "Reading \(formatToolName(toolName))")
        )
        .accessibilityAddTraits(.updatesFrequently)
    }

    private func formatToolName(_ name: String) -> String {
        switch name {
        case "fetchHealthData":
            return String(localized: "HealthKit data")
        default:
            return String(localized: "data")
        }
    }
}

#Preview {
    HealthChatView()
        .modelContainer(for: [HealthSession.self, HealthMetric.self])
}
