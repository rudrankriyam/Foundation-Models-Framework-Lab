//
//  RAGDocumentPickerView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/19/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct RAGDocumentPickerView: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab: DocumentPickerTab = .documents
    @State private var showFilePicker = false
    @State private var showAddTextSheet = false

    enum DocumentPickerTab: CaseIterable {
        case documents
        case samples

        var title: LocalizedStringKey {
            switch self {
            case .documents:
                "Sources"
            case .samples:
                "Samples"
            }
        }
    }

    private var allowedDocumentTypes: [UTType] {
        let markdown = UTType(filenameExtension: "md") ?? .plainText
        return [.pdf, .plainText, .html, .rtf, .text, markdown]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tab", selection: $selectedTab) {
                    ForEach(DocumentPickerTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch selectedTab {
                case .documents:
                    DocumentListView(viewModel: viewModel, showFilePicker: $showFilePicker)
                case .samples:
                    SamplesView(viewModel: viewModel)
                }
            }
            .navigationTitle("Sources")
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
                    Menu("Add Source", systemImage: "plus") {
                        Button("Import File", action: { showFilePicker = true })
                        Button("Add Text", action: { showAddTextSheet = true })
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: allowedDocumentTypes,
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel.indexDocument(from: url)
                        }
                    }
                case .failure(let error):
                    viewModel.errorMessage = String(
                        localized: "The file couldn’t be opened. \(error.localizedDescription)"
                    )
                    viewModel.showError = true
                }
            }
            .sheet(isPresented: $showAddTextSheet) {
                AddTextSheet(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Document List View

struct DocumentListView: View {
    @Bindable var viewModel: RAGChatViewModel
    @Binding var showFilePicker: Bool

    var body: some View {
        List {
            Section {
                Button {
                    showFilePicker = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text("Import a File")
                                .font(.headline)
                            Text("PDF, Markdown, plain text, HTML, or RTF")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "doc.badge.plus")
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .buttonStyle(.plain)
            }

            Section {
                if viewModel.indexedDocumentCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.indexedDocumentCount) indexed sources")
                    }
                } else if viewModel.hasIndexedContent {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("Indexed sources are available")
                    }
                } else {
                    ContentUnavailableView(
                        "No Sources",
                        systemImage: "doc.text",
                        description: Text("Import a file or add text to ask grounded questions.")
                    )
                }
            } header: {
                Text("Status")
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Samples View

struct SamplesView: View {
    @Bindable var viewModel: RAGChatViewModel

    @State private var showClearConfirmation = false

    var body: some View {
        List {
            Section {
                Button {
                    Task {
                        await viewModel.loadSampleDocuments()
                    }
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text("Add Sample Sources")
                                .font(.headline)
                            Text("Swift Concurrency, Foundation Models, and HealthKit")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "book.pages")
                            .foregroundStyle(.tint)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSearching)
            } header: {
                Text("Sample Data")
            } footer: {
                Text("Sample sources are clearly labeled and can be removed at any time.")
            }

            if viewModel.indexedDocumentCount > 0 || viewModel.hasIndexedContent {
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Delete All Sources")
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .confirmationDialog(
            "Delete all indexed sources?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Sources", role: .destructive) {
                Task {
                    await viewModel.resetDatabase()
                }
            }
        } message: {
            Text("This permanently deletes imported files, added text, and sample sources from the index.")
        }
    }
}

// MARK: - Add Text Sheet

struct AddTextSheet: View {
    @Bindable var viewModel: RAGChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var content = ""
    @State private var isIndexing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Source") {
                    TextField("Title", text: $title)
                }

                Section("Text") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
                }

                if isIndexing {
                    Section {
                        ProgressView("Adding source…")
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Label {
                            Text(errorMessage)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Add Text Source")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Add Source") {
                        addDocument()
                    }
                    .disabled(trimmedTitle.isEmpty || trimmedContent.isEmpty || isIndexing)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func addDocument() {
        isIndexing = true
        Task {
            let didIndex = await viewModel.indexText(
                trimmedContent,
                title: trimmedTitle
            )
            isIndexing = false
            if didIndex {
                dismiss()
            }
        }
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
