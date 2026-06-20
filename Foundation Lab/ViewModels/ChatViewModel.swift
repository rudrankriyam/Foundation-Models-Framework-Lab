//
//  ChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
import Observation
import Speech

@MainActor
@Observable
final class ChatViewModel {

    // MARK: - Published Properties

    var isLoading: Bool = false

    // MARK: - Voice State

    var voiceState: VoiceState = .idle
    @ObservationIgnored var speechRecognizer: SpeechRecognizer?
    @ObservationIgnored var speechObservationTask: Task<Void, Never>?
    @ObservationIgnored let permissionManager: PermissionManager
    @ObservationIgnored let speechSynthesizer: SpeechSynthesisService
    @ObservationIgnored let conversationEngine: FoundationLabConversationEngine
    var isSummarizing: Bool = false
    var isApplyingWindow: Bool = false
    var sessionCount: Int = 1
    var selectedModelRuntime: FoundationLabModelRuntime = .onDevice
    var selectedReasoningLevel: FoundationLabReasoningLevel = .none
    var samplingStrategy: SamplingStrategy = .default
    var topKSamplingValue: Int = 50
    var probabilityThresholdSamplingValue: Double = 0.9
    var useFixedSeed: Bool = false
    var temperature: Double?
    var maximumResponseTokens: Int?
    private(set) var selectedTools: [FoundationLabBuiltInTool] = []
    private(set) var appliedExperimentConfiguration: FoundationLabExperimentConfiguration?
    private(set) var activeExperimentLoadRevision: Int?
    private var samplingSeed: UInt64?
    var errorMessage: String?
    var showError: Bool = false

    // MARK: - Token Usage Tracking

    private(set) var currentTokenCount: Int = 0
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    var canStartTextGeneration: Bool {
        !isLoading && !session.isResponding && !voiceState.isActive
    }

    private var onDeviceAvailabilityMessage: String? {
        guard selectedModelRuntime == .onDevice else { return nil }

        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return String(localized: "This device does not support Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "Turn on Apple Intelligence in Settings, then try again.")
        case .unavailable(.modelNotReady):
            return String(localized: "The on-device model is still preparing. Try again when Apple Intelligence is ready.")
        @unknown default:
            return String(localized: "The on-device model is currently unavailable.")
        }
    }

    var canSelectPrivateCloudCompute: Bool {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            return model.isAvailable && !model.quotaUsage.isLimitReached
        }
        #endif

        return false
    }

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession

    // MARK: - Generation Options

    var generationOptions: FoundationLabGenerationOptions {
        let sampling: FoundationLabGenerationOptions.SamplingMode?

        switch samplingStrategy {
        case .default:
            sampling = nil
        case .greedy:
            sampling = .greedy
        case .sampling:
            let seed: UInt64? = useFixedSeed ? (samplingSeed ?? generateAndStoreSeed()) : nil
            sampling = .randomTop(topKSamplingValue, seed: seed)
        case .probabilityThreshold:
            let seed: UInt64? = useFixedSeed ? (samplingSeed ?? generateAndStoreSeed()) : nil
            sampling = .randomProbabilityThreshold(probabilityThresholdSamplingValue, seed: seed)
        }

        return FoundationLabGenerationOptions(
            sampling: sampling,
            temperature: temperature,
            maximumResponseTokens: maximumResponseTokens
        )
    }

    // MARK: - Initialization

    init(
        permissionManager: PermissionManager? = nil,
        speechSynthesizer: SpeechSynthesisService? = nil
    ) {
        self.permissionManager = permissionManager ?? PermissionManager()
        self.speechSynthesizer = speechSynthesizer ?? SpeechSynthesizer.shared
        let configuration = FoundationLabConversationConfiguration(
            baseInstructions: Self.defaultInstructions,
            summaryInstructions: """
            You are an expert at summarizing conversations. Create comprehensive summaries that \
            preserve all important context and details.
            """,
            summaryPromptPreamble: """
            Please summarize the following entire conversation comprehensively. Include all key points, \
            topics discussed, user preferences, and important context that would help continue the \
            conversation naturally:
            """,
            conversationUserLabel: "User:",
            conversationAssistantLabel: "Assistant:",
            continuationNote: """
            Continue the conversation naturally, referencing this context when relevant. \
            The user's next message is a continuation of your previous discussion.
            """,
            modelUseCase: .general,
            guardrails: .default,
            enableSlidingWindow: true,
            windowThreshold: AppConfiguration.TokenManagement.windowThreshold,
            targetWindowSize: AppConfiguration.TokenManagement.targetWindowSize,
            defaultMaxContextSize: AppConfiguration.TokenManagement.defaultMaxTokens
        )
        let engine = FoundationLabConversationEngine(configuration: configuration)
        self.conversationEngine = engine
        self.session = engine.session

        engine.onStateChange = { [weak self] in
            self?.syncConversationState()
        }
        syncConversationState()

        Task {
            await fetchContextSize()
        }
    }
}

// MARK: - Public Methods

extension ChatViewModel {
    @discardableResult
    func sendMessage(_ content: String) async -> ChatGenerationOutcome {
        guard !isLoading, !session.isResponding, !voiceState.isActive else { return .notStarted }
        if let availabilityMessage = onDeviceAvailabilityMessage {
            errorMessage = availabilityMessage
            showError = true
            return .failed(availabilityMessage)
        }
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await conversationEngine.sendStreamingMessage(
                content,
                generationOptions: generationOptions
            )
            syncConversationState()
            return .succeeded(response)
        } catch is CancellationError {
            return .cancelled
        } catch {
            let failureMessage = message(for: error)
            errorMessage = failureMessage
            showError = true
            return .failed(failureMessage)
        }
    }

    @discardableResult
    func applyExperiment(
        _ configuration: FoundationLabExperimentConfiguration,
        loadRevision: Int? = nil
    ) -> FoundationLabExperimentConfiguration {
        var effectiveConfiguration = configuration.normalized
        if effectiveConfiguration.modelRuntime == .privateCloudCompute,
           !canSelectPrivateCloudCompute {
            effectiveConfiguration.modelRuntime = .onDevice
            effectiveConfiguration.reasoningLevel = .none
            errorMessage = privateCloudComputeStatus
            showError = true
        } else if effectiveConfiguration.modelRuntime == .onDevice {
            effectiveConfiguration.reasoningLevel = .none
        }

        selectedModelRuntime = effectiveConfiguration.modelRuntime
        selectedReasoningLevel = effectiveConfiguration.reasoningLevel
        temperature = effectiveConfiguration.generationOptions.temperature
        maximumResponseTokens = effectiveConfiguration.generationOptions.maximumResponseTokens
        selectedTools = effectiveConfiguration.selectedTools
        applySamplingMode(effectiveConfiguration.generationOptions.sampling)

        conversationEngine.rebuild(
            baseInstructions: effectiveConfiguration.instructions,
            modelRuntime: effectiveConfiguration.modelRuntime,
            reasoningLevel: effectiveConfiguration.reasoningLevel,
            guardrails: .default,
            tools: selectedTools.map { $0.makeTool() }
        )
        conversationEngine.setMaxContextSize(provisionalContextSize(for: effectiveConfiguration.modelRuntime))
        if effectiveConfiguration.modelRuntime == configuration.modelRuntime {
            errorMessage = nil
            showError = false
        }
        syncConversationState()

        Task {
            await fetchContextSize(for: effectiveConfiguration.modelRuntime)
        }

        appliedExperimentConfiguration = effectiveConfiguration
        if let loadRevision {
            activeExperimentLoadRevision = loadRevision
        }
        return effectiveConfiguration
    }

    func applyGenerationOptions(_ options: FoundationLabGenerationOptions) {
        temperature = options.temperature
        maximumResponseTokens = options.maximumResponseTokens
        applySamplingMode(options.sampling)
    }

    func toggleTool(_ tool: FoundationLabBuiltInTool) {
        if let index = selectedTools.firstIndex(of: tool) {
            selectedTools.remove(at: index)
        } else {
            selectedTools.append(tool)
        }

        conversationEngine.rebuild(tools: selectedTools.map { $0.makeTool() })
        syncConversationState()
    }

    func clearChat() {
        conversationEngine.clear()
        isLoading = false
        errorMessage = nil
        showError = false
        syncConversationState()
    }

    func cancelGeneration() {
        conversationEngine.cancelActiveResponse()
    }

    func dismissError() {
        showError = false
        errorMessage = nil
        permissionManager.showPermissionAlert = false
        if case .error = voiceState {
            voiceState = .idle
        }
    }

    var shouldOfferPermissionSettings: Bool {
        permissionManager.showPermissionAlert
    }

    func openPermissionSettings() {
        permissionManager.openSettings()
        dismissError()
    }

}

extension ChatViewModel {
    static let defaultInstructions = """
    You are a helpful, friendly AI assistant. Engage in natural conversation and provide
    thoughtful, detailed responses.
    """

    func syncConversationState() {
        session = conversationEngine.session
        selectedModelRuntime = conversationEngine.modelRuntime
        selectedReasoningLevel = conversationEngine.reasoningLevel
        currentTokenCount = conversationEngine.currentTokenCount
        maxContextSize = conversationEngine.maxContextSize
        isSummarizing = conversationEngine.isSummarizing
        isApplyingWindow = conversationEngine.isApplyingWindow
        sessionCount = conversationEngine.sessionCount
    }

    func fetchContextSize(for runtime: FoundationLabModelRuntime? = nil) async {
        let requestedRuntime = runtime ?? selectedModelRuntime
        if requestedRuntime == .privateCloudCompute {
            let contextSize = await privateCloudComputeContextSize()
            guard selectedModelRuntime == requestedRuntime else { return }
            conversationEngine.setMaxContextSize(contextSize)
            syncConversationState()
            return
        }

        let contextSize = await AppConfiguration.TokenManagement.contextSize(
            modelUseCase: .general,
            guardrails: .default
        )
        guard selectedModelRuntime == requestedRuntime else { return }
        conversationEngine.setMaxContextSize(contextSize)
        syncConversationState()
    }

    func provisionalContextSize(for runtime: FoundationLabModelRuntime) -> Int {
        switch runtime {
        case .onDevice:
            AppConfiguration.TokenManagement.defaultMaxTokens
        case .privateCloudCompute:
            32_768
        }
    }

    func generateAndStoreSeed() -> UInt64 {
        let seed = UInt64.random(in: UInt64.min...UInt64.max)
        samplingSeed = seed
        return seed
    }

    func applySamplingMode(_ mode: FoundationLabGenerationOptions.SamplingMode?) {
        switch mode {
        case .none:
            samplingStrategy = .default
            useFixedSeed = false
        case .greedy:
            samplingStrategy = .greedy
            useFixedSeed = false
        case .randomTop(let top, let seed):
            samplingStrategy = .sampling
            topKSamplingValue = top
            samplingSeed = seed
            useFixedSeed = seed != nil
        case .randomProbabilityThreshold(let threshold, let seed):
            samplingStrategy = .probabilityThreshold
            probabilityThresholdSamplingValue = threshold
            samplingSeed = seed
            useFixedSeed = seed != nil
        }
    }

    var privateCloudComputeStatus: String {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            switch model.availability {
            case .available:
                if model.quotaUsage.isLimitReached {
                    return String(localized: "PCC daily usage limit reached.")
                }
                return String(localized: "Routes requests through Private Cloud Compute.")
            case .unavailable(.deviceNotEligible):
                return String(localized: "This device is not eligible for PCC.")
            case .unavailable(.systemNotReady):
                return String(localized: "PCC is not ready on this system.")
            @unknown default:
                return String(localized: "PCC is currently unavailable.")
            }
        }
        #endif

        return String(localized: "PCC requires Xcode 27 and iOS, macOS, visionOS, or watchOS 27.")
    }

    func privateCloudComputeContextSize() async -> Int {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()
            if let contextSize = try? await model.contextSize {
                return contextSize
            }
        }
        #endif

        return 32_768
    }
}
