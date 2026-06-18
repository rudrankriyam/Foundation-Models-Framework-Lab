//
//  StudioView.swift
//  FoundationLab
//
//  Created by Codex on 4/26/26.
//

import SwiftUI
import FoundationLabCore

struct StudioView: View {
    @State private var selectedWorkspace: StudioWorkspace = .promptTesting
    @State private var selectedStage: StudioPipelineStage = .settings
    @State private var promptText = "Summarize what makes Apple Foundation Models useful for an offline journaling app."
    @State private var selectedPromptVariants: Set<StudioPromptVariant> = Set(StudioPromptVariant.allCases)
    @State private var promptRuns: [StudioPromptRun] = []
    @State private var isRunningPromptTests = false
    @State private var promptTestError: String?
    @State private var studioCreatedAt = Date.now

#if os(iOS)
    @State private var isShowingInspector = false
#endif

#if os(macOS)
    @State private var adapterStudioViewModel = AdapterStudioViewModel()
#endif

    private let generateTextUseCase = GenerateTextUseCase()

    var body: some View {
        StudioWorkbenchView(
            workspace: $selectedWorkspace,
            stage: $selectedStage,
            isRunning: isRunningPromptTests,
            canRun: canRunPromptTests,
            run: runPromptTests,
            content: stageContent,
            inspector: studioInspector
        )
        .navigationTitle("Studio")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
#if os(iOS)
            if selectedWorkspace == .promptTesting {
                ToolbarItem(placement: .primaryAction) {
                    Button(
                        "Run",
                        systemImage: isRunningPromptTests ? "hourglass" : "play.fill",
                        action: runPromptTests
                    )
                    .disabled(isRunningPromptTests || !canRunPromptTests)
                }
            }

            ToolbarItem(placement: .secondaryAction) {
                Button("Studio Details", systemImage: "sidebar.trailing") {
                    isShowingInspector.toggle()
                }
            }
#endif
        }
#if os(iOS)
        .inspector(isPresented: $isShowingInspector) {
            ScrollView {
                studioInspector
            }
            .presentationDetents([.medium, .large])
        }
#endif
    }

    @ViewBuilder
    private var stageContent: some View {
        if selectedWorkspace == .adapterComparison {
            adapterStudioContent
        } else if selectedWorkspace == .benchmarkRuns {
            AppBenchStudioContent(stage: selectedStage)
        } else if selectedWorkspace == .structuredOutput || selectedWorkspace == .capabilityMatrix {
            ContentUnavailableView(
                selectedWorkspace.title,
                systemImage: selectedWorkspace.icon,
                description: Text("This workspace is planned for a future Foundation Lab update.")
            )
            .frame(maxWidth: .infinity, minHeight: 320)
        } else {
            StudioPromptStageView(
                stage: $selectedStage,
                promptText: $promptText,
                selectedVariants: $selectedPromptVariants,
                runs: promptRuns,
                isRunning: isRunningPromptTests,
                errorMessage: promptTestError
            )
        }
    }

    @ViewBuilder
    private var adapterStudioContent: some View {
#if os(macOS)
        AdapterStudioContent(
            stage: selectedStage,
            viewModel: adapterStudioViewModel
        )
#else
        AdapterStudioContent(stage: selectedStage)
#endif
    }

    private var studioInspector: some View {
        StudioActivityInspector(
            workspace: selectedWorkspace,
            promptRuns: promptRuns,
            selectedVariantCount: selectedPromptVariants.count,
            createdAt: studioCreatedAt
        )
    }

    private var canRunPromptTests: Bool {
        selectedWorkspace == .promptTesting &&
        !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedPromptVariants.isEmpty
    }

    private func runPromptTests() {
        guard canRunPromptTests, !isRunningPromptTests else { return }

        isRunningPromptTests = true

        Task {
            await performPromptTests()
        }
    }

    @MainActor
    private func performPromptTests() async {
        let trimmedPrompt = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty, !selectedPromptVariants.isEmpty else {
            isRunningPromptTests = false
            return
        }

        promptTestError = nil
        selectedStage = .runs
        defer { isRunningPromptTests = false }

        var newRuns: [StudioPromptRun] = []
        let variants = StudioPromptVariant.allCases.filter { selectedPromptVariants.contains($0) }

        do {
            for variant in variants {
                let startedAt = Date.now
                let result = try await generateTextUseCase.execute(
                    TextGenerationRequest(
                        prompt: trimmedPrompt,
                        systemPrompt: variant.systemPrompt,
                        generationOptions: variant.generationOptions,
                        context: CapabilityInvocationContext(
                            source: .app,
                            localeIdentifier: Locale.current.identifier
                        )
                    )
                )

                newRuns.append(
                    StudioPromptRun(
                        variant: variant,
                        prompt: trimmedPrompt,
                        output: result.content,
                        duration: Date.now.timeIntervalSince(startedAt),
                        tokenCount: result.metadata.tokenCount,
                        finishedAt: Date.now
                    )
                )
            }

            promptRuns = newRuns + promptRuns
        } catch {
            if !newRuns.isEmpty {
                promptRuns = newRuns + promptRuns
            }

            promptTestError = error.localizedDescription
            selectedStage = newRuns.isEmpty ? .settings : .runs
        }
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
}
