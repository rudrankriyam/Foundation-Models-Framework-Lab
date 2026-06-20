//
//  GeminiVideoInputView.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import SwiftUI
import UniformTypeIdentifiers

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct GeminiVideoInputView: View {
    @State private var viewModel = GeminiVideoInputViewModel()
    @State private var isChoosingVideo = false
    @State private var isShowingAPIKey = false

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Spacing.large) {
                        videoSection
                            .frame(minWidth: 560)

                        promptSection
                            .frame(minWidth: 320, idealWidth: 360, maxWidth: 400)
                    }

                    VStack(alignment: .leading, spacing: Spacing.large) {
                        videoSection
                        promptSection
                    }
                }

                if !viewModel.result.isEmpty {
                    ResultDisplay(
                        result: viewModel.result,
                        isSuccess: viewModel.resultIsSuccess
                    )
                }

                CodeDisclosure(code: viewModel.codeExample)
            }
            .frame(maxWidth: 1_280)
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Gemini Video")
        .fileImporter(
            isPresented: $isChoosingVideo,
            allowedContentTypes: [.movie],
            allowsMultipleSelection: false
        ) { result in
            handleVideoImport(result)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: showAPIKey) {
                    Label(
                        "API Key",
                        systemImage: viewModel.apiKey.isEmpty ? "key" : "key.fill"
                    )
                }
                .help(viewModel.apiKey.isEmpty ? "Add Gemini API key" : "Edit Gemini API key")
            }
        }
        .sheet(isPresented: $isShowingAPIKey) {
            GeminiAPIKeySheet(viewModel: viewModel)
        }
        .onDisappear(perform: viewModel.cancelAnalysis)
    }

    private var videoSection: some View {
        Xcode27Section("Video Input") {
            if let videoURL = viewModel.videoURL {
                GeminiVideoPreview(url: videoURL)
                    .aspectRatio(16 / 9, contentMode: .fit)

                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(viewModel.videoName)
                            .font(.subheadline)
                            .bold()
                            .lineLimit(1)

                        Text(viewModel.videoSize)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose Video", action: chooseVideo)
                    .buttonStyle(.bordered)
                }
            } else {
                ContentUnavailableView(
                    "Sample Video Missing",
                    systemImage: "video.slash",
                    description: Text("Choose an MP4, MOV, or M4V file to continue.")
                )

                Button("Choose Video", action: chooseVideo)
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var promptSection: some View {
        Xcode27Section("Ask Gemini") {
            TextField("Describe what Gemini should inspect", text: $viewModel.prompt, axis: .vertical)
                .lineLimit(8...12)
                .textFieldStyle(.roundedBorder)

            if let errorMessage = viewModel.errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if viewModel.isRunning {
                Button(role: .cancel, action: viewModel.cancelAnalysis) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
            } else {
                Button("Analyze Video", systemImage: "play.fill", action: viewModel.startAnalysis)
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func chooseVideo() {
        isChoosingVideo = true
    }

    private func showAPIKey() {
        isShowingAPIKey = true
    }

    private func handleVideoImport(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            if let url = urls.first {
                viewModel.selectVideo(url)
            }
        case let .failure(error):
            viewModel.errorMessage = error.localizedDescription
        }
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct GeminiAPIKeySheet: View {
    let viewModel: GeminiVideoInputViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String

    init(viewModel: GeminiVideoInputViewModel) {
        self.viewModel = viewModel
        _apiKey = State(initialValue: viewModel.apiKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("AI Studio API key", text: $apiKey)
                        .privacySensitive()
                } footer: {
                    Text("Kept in memory for this session.")
                }
            }
            .navigationTitle("Gemini API Key")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.apiKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                        dismiss()
                    }
                }
            }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 180)
#else
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
#endif
    }
}

#Preview {
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
        NavigationStack {
            GeminiVideoInputView()
        }
    }
}
#else
struct GeminiVideoInputView: View {
    var body: some View {
        ContentUnavailableView(
            "Xcode 27 Required",
            systemImage: "video.slash",
            description: Text("Build with Xcode 27 to use custom LanguageModel executors.")
        )
        .navigationTitle("Gemini Video")
    }
}
#endif
