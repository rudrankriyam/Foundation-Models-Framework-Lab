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

    enum DocumentPickerTab: String, CaseIterable {
        case documents = "Documents"
        case samples = "Samples"
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
                        Text(tab.rawValue).tag(tab)
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
            .navigationTitle("RAG Documents")
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
                    Menu("Add Document", systemImage: "plus") {
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
                    viewModel.errorMessage = String(localized: "Failed to access file: \(error.localizedDescription)")
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
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 40, height: 40)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("Import Document")
                                .font(.headline)
                            Text("PDF, Markdown, Text, HTML, RTF")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section {
                if viewModel.indexedDocumentCount > 0 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(viewModel.indexedDocumentCount) sources indexed")
                    }
                } else if viewModel.hasIndexedContent {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Indexed content present")
                    }
                } else {
                    ContentUnavailableView(
                        "No Documents",
                        systemImage: "doc.text",
                        description: Text("Import documents to enable RAG-powered conversations")
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
                    HStack {
                        Image(systemName: "book.pages")
                            .font(.title2)
                            .foregroundStyle(.purple)
                            .frame(width: 40, height: 40)
                            .background(Color.purple.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text("Load Sample Documents")
                                .font(.headline)
                            Text("Swift Concurrency, Foundation Models, HealthKit")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if viewModel.isSearching {
                            ProgressView()
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSearching)
            } header: {
                Text("Sample Data")
            } footer: {
                Text("Load pre-built sample documents to test RAG functionality")
            }

            if viewModel.indexedDocumentCount > 0 || viewModel.hasIndexedContent {
                Section {
                    Button(role: .destructive) {
                        showClearConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                            Text("Clear All Documents")
                        }
                    }
                }
            }
        }
        .listStyle(.inset)
        .alert("Clear All Documents?", isPresented: $showClearConfirmation) {
            Button("Clear All", role: .destructive) {
                Task {
                    await viewModel.resetDatabase()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all indexed documents. This action cannot be undone.")
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
                Section("Document Info") {
                    TextField("Title", text: $title)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 200)
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
            .navigationTitle("Add Text")
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
                    Button("Add") {
                        addDocument()
                    }
                    .disabled(trimmedTitle.isEmpty || trimmedContent.isEmpty || isIndexing)
                }
            }
            .overlay {
                if isIndexing {
                    ProgressView("Indexing...")
                        .padding()
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
