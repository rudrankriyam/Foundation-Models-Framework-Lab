//
//  RAGChatView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI

struct RAGChatView: View {
    @State private var viewModel = RAGChatViewModel()
    @FocusState private var isTextFieldFocused: Bool
    @State private var question = ""
    @State private var answer = ""
    @State private var sources: [RAGChunk] = []

    private let suggestions = [
        String(localized: "Summarize the main points of this document."),
        String(localized: "What does the document say about its goals?"),
        String(localized: "List the key takeaways in bullets."),
        String(localized: "Where does it mention requirements or constraints?")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                documentsSection
                questionSection

                if isWorking {
                    statusRow
                }

                if !answer.isEmpty {
                    ResultDisplay(result: answer, isSuccess: true, tokenCount: viewModel.lastTokenCount)
                }

                if !sources.isEmpty {
                    sourcesSection
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Doc Q&A")
        .task {
            await viewModel.loadFromDatabase()
        }
        .onDisappear {
            viewModel.tearDown()
        }
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .scrollDismissesKeyboard(.interactively)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showDocumentPicker = true
                } label: {
                    Label("Documents", systemImage: "doc.text")
                }
            }
        }
        .sheet(isPresented: $viewModel.showDocumentPicker) {
            RAGDocumentPickerView(viewModel: viewModel)
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
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Documents")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: Spacing.medium) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.title3)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(documentStatusTitle)
                        .font(.headline)
                    Text(documentStatusSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Manage") {
                    viewModel.showDocumentPicker = true
                }
                .buttonStyle(.glassProminent)
            }
            .padding(Spacing.medium)
            .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
        }
    }

    private var questionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Question")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                TextField("Ask a question about your documents...", text: $question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .padding(Spacing.medium)
                    .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
                    .onSubmit {
                        askQuestion()
                    }
            }

            PromptSuggestions(suggestions: suggestions) { selected in
                question = selected
            }

            ToolExecuteButton("Ask", systemImage: "arrow.up.circle.fill", isRunning: isWorking) {
                askQuestion()
            }
            .disabled(!canAskQuestion)
        }
    }

    private var statusRow: some View {
        HStack(spacing: Spacing.small) {
            ProgressView()
                .scaleEffect(0.8)
            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Sources")
                .font(.headline)
                .foregroundStyle(.secondary)

            ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                RAGSourceCard(index: index + 1, source: source)
            }
        }
    }

    private var hasDocuments: Bool {
        viewModel.indexedDocumentCount > 0 || viewModel.hasIndexedContent
    }

    private var documentStatusTitle: String {
        if viewModel.indexedDocumentCount > 0 {
            return String(localized: "\(viewModel.indexedDocumentCount) sources indexed")
        }
        if viewModel.hasIndexedContent {
            return String(localized: "Indexed content available")
        }
        return String(localized: "No documents indexed")
    }

    private var documentStatusSubtitle: String {
        hasDocuments
            ? String(localized: "Ask a question and we'll cite the top sources.")
            : String(localized: "Import a PDF or text file to get started.")
    }

    private var statusText: String {
        viewModel.isSearching
            ? String(localized: "Processing...")
            : String(localized: "Generating answer...")
    }

    private var trimmedQuestion: String {
        question.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isWorking: Bool {
        viewModel.isSearching || viewModel.isGenerating
    }

    private var canAskQuestion: Bool {
        hasDocuments && !trimmedQuestion.isEmpty && !isWorking
    }

    private func askQuestion() {
        let trimmed = trimmedQuestion
        guard hasDocuments, !trimmed.isEmpty, !isWorking else { return }
        isTextFieldFocused = false
        answer = ""
        sources = []

        Task {
            await viewModel.askQuestion(
                trimmed,
                onSources: { sources in
                    self.sources = sources
                },
                onUpdate: { updated in
                    answer = updated
                }
            )
        }
    }
}
