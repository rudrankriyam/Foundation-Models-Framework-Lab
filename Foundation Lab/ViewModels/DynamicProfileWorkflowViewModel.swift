//
//  DynamicProfileWorkflowViewModel.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation
import FoundationModels
import Observation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class DynamicProfileWorkflowViewModel {
    var prompt = DynamicProfileWorkflowStage.inspect.defaultPrompt
    private(set) var turns: [DynamicProfileWorkflowTurn] = []
    private(set) var isRunning = false
    private(set) var isStopping = false
    private(set) var transcriptEntryCount = 0
    var errorMessage: String?

    @ObservationIgnored
    private let state = DynamicProfileWorkflowState()
    @ObservationIgnored
    private let privateCloudComputeModel = PrivateCloudComputeLanguageModel()
    @ObservationIgnored
    private var recorder = LocalReleaseRecordExecutionRecorder()
    @ObservationIgnored
    private var session: LanguageModelSession?
    @ObservationIgnored
    private var activeRunID: UUID?
    @ObservationIgnored
    private var runTask: Task<Void, Never>?

    var stage: DynamicProfileWorkflowStage { state.stage }
    var reviewRuntime: DynamicProfileReviewRuntime { state.reviewRuntime }

    var activeRuntime: DynamicProfileReviewRuntime {
        stage == .inspect ? .onDevice : reviewRuntime
    }

    var isExecuting: Bool {
        isRunning || isStopping
    }

    var canRun: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isExecuting
            && readinessIssue == nil
    }

    var readinessIssue: String? {
        switch activeRuntime {
        case .onDevice:
            return systemModelReadinessIssue
        case .privateCloudCompute:
            return privateCloudComputeReadinessIssue
        }
    }

    func selectStage(_ stage: DynamicProfileWorkflowStage) {
        guard !isExecuting, state.stage != stage else { return }
        state.stage = stage
        prompt = stage.defaultPrompt
        errorMessage = nil
    }

    func selectReviewRuntime(_ runtime: DynamicProfileReviewRuntime) {
        guard !isExecuting, state.reviewRuntime != runtime else { return }
        state.reviewRuntime = runtime
        errorMessage = nil
    }

    func startRun() {
        guard canRun else {
            errorMessage = readinessIssue
            return
        }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let runID = UUID()
        activeRunID = runID
        isRunning = true
        isStopping = false
        errorMessage = nil

        runTask = Task { @MainActor [weak self] in
            await self?.performRun(prompt: trimmedPrompt, id: runID)
        }
    }

    func cancelRun() {
        guard isRunning, !isStopping else { return }
        isStopping = true
        runTask?.cancel()
    }

    func reset() {
        guard !isExecuting else { return }
        state.stage = .inspect
        state.reviewRuntime = .privateCloudCompute
        state.requiresInspectionToolCall = false
        prompt = DynamicProfileWorkflowStage.inspect.defaultPrompt
        turns = []
        transcriptEntryCount = 0
        errorMessage = nil
        session = nil
        recorder = LocalReleaseRecordExecutionRecorder()
    }

    var codeExample: String {
        """
        import FoundationModels
        import Observation

        @Observable
        final class WorkflowState {
            enum Stage { case inspect, review }
            var stage = Stage.inspect
            var usePrivateCloudCompute = true
        }

        struct WorkflowProfile: LanguageModelSession.DynamicProfile {
            let state: WorkflowState
            let tool: LocalReleaseRecordTool
            let pccModel = PrivateCloudComputeLanguageModel()

            var body: some LanguageModelSession.DynamicProfile {
                switch state.stage {
                case .inspect:
                    LanguageModelSession.Profile {
                        Instructions("Inspect with the read-only tool.")
                        tool
                    }
                    .model(SystemLanguageModel.default)
                    .toolCallingMode(.required)

                case .review:
                    if state.usePrivateCloudCompute {
                        LanguageModelSession.Profile {
                            Instructions("Review evidence already in the session history.")
                        }
                        .model(pccModel)
                        .reasoningLevel(.moderate)
                    } else {
                        LanguageModelSession.Profile {
                            Instructions("Review evidence already in the session history.")
                        }
                        .model(SystemLanguageModel.default)
                    }
                }
            }
        }

        let state = WorkflowState()
        let recorder = LocalReleaseRecordExecutionRecorder()
        let session = LanguageModelSession(
            profile: WorkflowProfile(
                state: state,
                tool: LocalReleaseRecordTool(recorder: recorder)
            )
        )

        try await session.respond(to: "Inspect the sample release record.")
        state.stage = .review
        try await session.respond(to: "Which checks are still unknown?")
        """
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension DynamicProfileWorkflowViewModel {
    var systemModelReadinessIssue: String? {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            return String(localized: "This device is not eligible for the on-device system language model.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "Apple Intelligence is not enabled.")
        case .unavailable(.modelNotReady):
            return String(localized: "The on-device system language model is not ready.")
        @unknown default:
            return String(localized: "The on-device system language model is unavailable.")
        }

        if stage == .inspect, !model.capabilities.contains(.toolCalling) {
            return String(localized: "The system language model does not report tool-calling support on this runtime.")
        }
        return nil
    }

    var privateCloudComputeReadinessIssue: String? {
        switch privateCloudComputeModel.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            return String(localized: "Device not eligible")
        case .unavailable(.systemNotReady):
            return String(localized: "System not ready")
        @unknown default:
            return String(localized: "Private Cloud Compute is currently unavailable.")
        }

        if privateCloudComputeModel.quotaUsage.isLimitReached {
            return String(localized: "Private Cloud Compute daily usage limit reached.")
        }
        return nil
    }

    func currentSession(recorder: LocalReleaseRecordExecutionRecorder) -> LanguageModelSession {
        if let session {
            return session
        }

        let newSession = LanguageModelSession(
            profile: DynamicProfileWorkflowProfile(
                state: state,
                tool: LocalReleaseRecordTool(recorder: recorder),
                privateCloudComputeModel: privateCloudComputeModel
            )
        )
        session = newSession
        return newSession
    }

    func performRun(prompt: String, id: UUID) async {
        let selectedStage = stage
        let selectedRuntime = activeRuntime
        let currentRecorder = recorder
        let modelSession = currentSession(recorder: currentRecorder)
        let previousOutputs = await currentRecorder.snapshot().count
        state.requiresInspectionToolCall = selectedStage == .inspect
        let clock = ContinuousClock()
        let startedAt = clock.now

        defer {
            state.requiresInspectionToolCall = false
            if activeRunID == id {
                transcriptEntryCount = modelSession.transcript.count
                activeRunID = nil
                runTask = nil
                isRunning = false
                isStopping = false
            }
        }

        do {
            let response = try await modelSession.respond(
                to: prompt,
                metadata: ["foundation-lab-workflow-stage": selectedStage.rawValue]
            )
            try Task.checkCancellation()
            guard activeRunID == id else { return }

            let outputs = await currentRecorder.snapshot()
            let turn = DynamicProfileWorkflowTurn(
                stage: selectedStage,
                runtime: selectedRuntime,
                prompt: prompt,
                response: response.content,
                toolOutputs: Array(outputs.dropFirst(previousOutputs)),
                elapsed: startedAt.duration(to: clock.now),
                inputTokens: response.usage.input.totalTokenCount,
                cachedInputTokens: response.usage.input.cachedTokenCount,
                outputTokens: response.usage.output.totalTokenCount,
                reasoningTokens: response.usage.output.reasoningTokenCount,
                totalTokens: response.usage.totalTokenCount,
                transcriptEntryCount: modelSession.transcript.count
            )
            turns.append(turn)
            transcriptEntryCount = modelSession.transcript.count
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            guard activeRunID == id else { return }
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }
}
#endif
