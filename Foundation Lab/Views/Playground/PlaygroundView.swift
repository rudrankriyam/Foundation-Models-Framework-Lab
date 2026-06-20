import FoundationLabCore
import FoundationModels
import SwiftUI

struct PlaygroundView: View {
    @Environment(ExperimentStore.self) private var experimentStore
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let viewModel: ChatViewModel
    @State private var messageText = ""
    @State private var scrollID: String?
    @State private var showsInspector = false
    @State private var showsSettings = false
    @State private var showsDiscardConfirmation = false
    @State private var pendingVoiceConfiguration: FoundationLabExperimentConfiguration?
    @FocusState private var isPromptFocused: Bool

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            PlaygroundHeaderView(
                configuration: experimentStore.activeExperiment,
                toolCount: experimentStore.activeExperiment.selectedTools.count
            )

            Divider()

            TokenUsageBar(
                currentTokenCount: viewModel.currentTokenCount,
                maxContextSize: viewModel.maxContextSize,
                tokenUsageFraction: viewModel.tokenUsageFraction
            )

            PlaygroundTranscriptView(
                viewModel: viewModel,
                configuration: experimentStore.activeExperiment,
                scrollID: $scrollID,
                runSuggestedPrompt: runSuggestedPrompt,
                openLibrary: navigationCoordinator.openLibrary
            )

            ChatInputView(
                messageText: $messageText,
                chatViewModel: viewModel,
                isTextFieldFocused: $isPromptFocused,
                onSend: run,
                onVoiceWillSend: prepareVoiceRun,
                onVoiceCompleted: recordVoiceRun
            )
        }
        .environment(viewModel)
        .navigationTitle("Playground")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Configure Experiment", systemImage: "sidebar.trailing") {
                    showsInspector.toggle()
                }
#if os(macOS)
                .keyboardShortcut("i", modifiers: [.command, .option])
#endif

                Menu("Experiment Actions", systemImage: "ellipsis.circle") {
                    Button("New Experiment", systemImage: "plus", action: requestNewExperiment)
                        .keyboardShortcut("n", modifiers: .command)
                    Button("Save Experiment", systemImage: "square.and.arrow.down") {
                        Task {
                            await saveExperiment()
                        }
                    }
                        .keyboardShortcut("s", modifiers: .command)
                    Button("Settings", systemImage: "gear") {
                        showsSettings = true
                    }
                }
            }
        }
        .inspector(isPresented: $showsInspector) {
            PlaygroundInspectorView(
                experimentStore: experimentStore,
                viewModel: viewModel,
                applyConfiguration: applyInspectorConfiguration
            )
            .inspectorColumnWidth(min: 300, ideal: 360, max: 440)
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .alert("Experiment Error", isPresented: $viewModel.showError) {
            if viewModel.shouldOfferPermissionSettings {
                Button("Open Settings", action: viewModel.openPermissionSettings)
            }
            Button("Dismiss", role: .cancel, action: viewModel.dismissError)
        } message: {
            if let message = viewModel.errorMessage {
                Text(message)
            } else {
                Text("The experiment could not run.")
            }
        }
        .confirmationDialog(
            "Discard unsaved experiment?",
            isPresented: $showsDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard and Create New", role: .destructive, action: createExperiment)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this experiment first if you want to keep its configuration.")
        }
        .task(id: experimentStore.activeExperimentLoadRevision) {
            loadActiveExperiment()
        }
        .task {
            showsInspector = horizontalSizeClass != .compact
        }
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            showsInspector = sizeClass != .compact
        }
    }
}

private extension PlaygroundView {
    private func loadActiveExperiment() {
        guard viewModel.activeExperimentLoadRevision != experimentStore.activeExperimentLoadRevision else {
            return
        }
        let configuration = experimentStore.activeExperiment
        let effectiveConfiguration = viewModel.applyExperiment(
            configuration,
            loadRevision: experimentStore.activeExperimentLoadRevision
        )
        if effectiveConfiguration != configuration {
            experimentStore.updateActiveExperiment(effectiveConfiguration)
        }
        pendingVoiceConfiguration = nil
        messageText = effectiveConfiguration.prompt
        scrollID = "bottom"
    }

    private func runSuggestedPrompt() {
        let prompt = experimentStore.activeExperiment.prompt
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            navigationCoordinator.openLibrary()
            return
        }

        messageText = ""
        Task {
            await run(prompt)
        }
    }

    private func run(_ prompt: String) async {
        let startedAt = Date.now
        let configuration = ensureConfigurationIsApplied(
            configurationSnapshot(prompt: prompt)
        )
        experimentStore.updateActiveExperiment(configuration)
        let matchingPromptCountBeforeRun = transcriptPromptCount(matching: prompt)
        let outcome = await viewModel.sendMessage(prompt)
        let response: String
        let errorMessage: String?
        let status: FoundationLabExperimentRun.Status
        switch outcome {
        case .succeeded(let content):
            response = content
            errorMessage = nil
            status = .succeeded
        case .cancelled:
            response = ""
            errorMessage = nil
            status = .cancelled
        case .failed(let message):
            response = ""
            errorMessage = message
            status = .failed
        case .notStarted:
            return
        }
        let events = capturedRunEvents(
            ensuringPrompt: prompt,
            startedAt: startedAt,
            matchingPromptCountBeforeRun: matchingPromptCountBeforeRun
        )

        let run = FoundationLabExperimentRun(
            configuration: configuration,
            prompt: prompt,
            response: response,
            startedAt: startedAt,
            duration: Date.now.timeIntervalSince(startedAt),
            provider: "Apple Foundation Models",
            modelIdentifier: modelIdentifier(for: configuration.modelRuntime),
            tokenCount: viewModel.currentTokenCount,
            errorMessage: errorMessage,
            status: status,
            events: events
        )
        experimentStore.record(run)
    }

    private func configurationSnapshot(prompt: String? = nil) -> FoundationLabExperimentConfiguration {
        var configuration = experimentStore.activeExperiment
        configuration.prompt = prompt ?? configuration.prompt
        configuration.modifiedAt = .now
        return configuration
    }

    private func applyInspectorConfiguration() {
        let configuration = ensureConfigurationIsApplied(configurationSnapshot())
        experimentStore.updateActiveExperiment(configuration)
        scrollID = "bottom"
    }

    private func createExperiment() {
        experimentStore.newExperiment()
        isPromptFocused = true
    }

    private func requestNewExperiment() {
        if experimentStore.hasUnsavedActiveExperiment, hasMeaningfulActiveExperiment {
            showsDiscardConfirmation = true
        } else {
            createExperiment()
        }
    }

    private func saveExperiment() async {
        let configuration = ensureConfigurationIsApplied(configurationSnapshot())
        experimentStore.updateActiveExperiment(configuration)
        await experimentStore.saveActiveExperiment()
    }

    private func prepareVoiceRun() {
        let configuration = ensureConfigurationIsApplied(configurationSnapshot())
        experimentStore.updateActiveExperiment(configuration)
        pendingVoiceConfiguration = configuration
    }

    private func recordVoiceRun(
        prompt: String,
        response: String,
        startedAt: Date,
        duration: TimeInterval
    ) {
        var configuration = pendingVoiceConfiguration ?? configurationSnapshot()
        configuration.prompt = prompt
        configuration.modifiedAt = .now
        experimentStore.updateActiveExperiment(configuration)
        pendingVoiceConfiguration = nil

        experimentStore.record(
            FoundationLabExperimentRun(
                configuration: configuration,
                prompt: prompt,
                response: response,
                startedAt: startedAt,
                duration: duration,
                provider: "Apple Foundation Models",
                modelIdentifier: modelIdentifier(for: configuration.modelRuntime),
                tokenCount: viewModel.currentTokenCount,
                events: capturedRunEvents()
            )
        )
    }

    private func ensureConfigurationIsApplied(
        _ configuration: FoundationLabExperimentConfiguration
    ) -> FoundationLabExperimentConfiguration {
        let normalizedConfiguration = configuration.normalized
        viewModel.applyGenerationOptions(normalizedConfiguration.generationOptions)
        guard requiresSessionRebuild(
            normalizedConfiguration,
            comparedWith: viewModel.appliedExperimentConfiguration
        ) else {
            return normalizedConfiguration
        }

        let effectiveConfiguration = viewModel.applyExperiment(normalizedConfiguration)
        return effectiveConfiguration
    }

    private func requiresSessionRebuild(
        _ configuration: FoundationLabExperimentConfiguration,
        comparedWith appliedConfiguration: FoundationLabExperimentConfiguration?
    ) -> Bool {
        guard let appliedConfiguration else { return true }
        return configuration.instructions != appliedConfiguration.instructions
            || configuration.modelRuntime != appliedConfiguration.modelRuntime
            || configuration.reasoningLevel != appliedConfiguration.reasoningLevel
            || configuration.selectedTools != appliedConfiguration.selectedTools
    }

    private func modelIdentifier(for runtime: FoundationLabModelRuntime) -> String {
        switch runtime {
        case .onDevice:
            return "SystemLanguageModel"
        case .privateCloudCompute:
            return "PrivateCloudComputeLanguageModel"
        }
    }

    private var hasMeaningfulActiveExperiment: Bool {
        let configuration = experimentStore.activeExperiment
        let isDefaultName = configuration.name.isEmpty
            || configuration.name == "Untitled Experiment"
            || configuration.name == String(localized: "Untitled Experiment")
        return !isDefaultName
            || !configuration.summary.isEmpty
            || !configuration.prompt.isEmpty
            || !configuration.instructions.isEmpty
            || !configuration.selectedTools.isEmpty
            || viewModel.session.transcript.count > 1
    }

    private func capturedRunEvents(
        ensuringPrompt currentPrompt: String? = nil,
        startedAt: Date? = nil,
        matchingPromptCountBeforeRun: Int = 0
    ) -> [FoundationLabExperimentEvent] {
        var events = viewModel.session.transcript.flatMap { capturedEvents(for: $0) }
        let capturedPromptCount = currentPrompt.map { prompt in
            events.count(where: { $0.role == .user && $0.text == prompt })
        } ?? 0
        if let currentPrompt, capturedPromptCount <= matchingPromptCountBeforeRun {
            events.append(
                FoundationLabExperimentEvent(
                    role: .user,
                    text: currentPrompt,
                    timestamp: startedAt
                )
            )
        }

        return events
    }

    private func transcriptPromptCount(matching text: String) -> Int {
        viewModel.session.transcript.count(where: { entry in
            guard case .prompt(let prompt) = entry else { return false }
            return transcriptText(from: prompt.segments) == text
        })
    }

    private func capturedEvents(for entry: Transcript.Entry) -> [FoundationLabExperimentEvent] {
        switch entry {
        case .instructions(let instructions):
            return [FoundationLabExperimentEvent(role: .system, text: transcriptText(from: instructions.segments))]
        case .prompt(let prompt):
            return [FoundationLabExperimentEvent(role: .user, text: transcriptText(from: prompt.segments))]
        case .response(let response):
            return [FoundationLabExperimentEvent(role: .assistant, text: transcriptText(from: response.segments))]
        case .toolCalls(let calls):
            return calls.map { call in
                FoundationLabExperimentEvent(
                    role: .assistant,
                    kind: .toolCall,
                    text: call.arguments.jsonString,
                    toolName: call.toolName
                )
            }
        case .toolOutput(let output):
            return [FoundationLabExperimentEvent(
                role: .tool,
                kind: .toolResult,
                text: transcriptText(from: output.segments),
                toolName: output.toolName
            )]
        #if compiler(>=6.4)
        case .reasoning(let reasoning):
            if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                return [FoundationLabExperimentEvent(
                    role: .assistant,
                    text: transcriptText(from: reasoning.segments)
                )]
            }
            return []
        #endif
        @unknown default:
            return []
        }
    }

    private func transcriptText(from segments: [Transcript.Segment]) -> String {
        segments.compactMap { segment in
            switch segment {
            case .text(let text):
                return text.content
            case .structure(let structure):
                return structure.content.jsonString
            #if compiler(>=6.4)
            case .attachment(let attachment):
                if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
                    return attachment.label.map { "[Attachment: \($0)]" } ?? "[Image attachment]"
                }
                return nil
            case .custom:
                return "[Custom model content]"
            #endif
            @unknown default:
                return nil
            }
        }
        .joined(separator: "\n")
    }
}

#Preview {
    NavigationStack {
        PlaygroundView(viewModel: ChatViewModel())
    }
    .environment(ExperimentStore.shared)
    .environment(NavigationCoordinator.shared)
}
