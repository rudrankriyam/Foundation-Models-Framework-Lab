//
//  ToolCallingModeLabViewModel.swift
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
final class ToolCallingModeLabViewModel {
    static let defaultPrompt = "What validation result is stored for the Foundation Lab release record?"

    var prompt = defaultPrompt {
        didSet {
            guard prompt != oldValue else { return }
            invalidateEditedPrompt()
        }
    }
    var results = ToolCallingExperimentMode.allCases.map { ToolCallingModeRunResult.pending($0) }
    var isRunning = false
    var isStoppingRun = false
    var activeMode: ToolCallingExperimentMode?
    var errorMessage: String?

    private var activeRunID: UUID?
    private var runTask: Task<Void, Never>?

    var canRun: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isRunning
            && !isStoppingRun
            && readinessIssue == nil
    }

    var readinessIssue: String? {
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

        guard model.capabilities.contains(.toolCalling) else {
            return String(localized: "The system language model does not report tool-calling support on this runtime.")
        }

        return nil
    }

    func startComparison() {
        guard !isRunning, !isStoppingRun else { return }
        guard let trimmedPrompt = nonemptyPrompt else { return }
        if let readinessIssue {
            errorMessage = readinessIssue
            return
        }
        beginComparison(prompt: trimmedPrompt)
    }

    func cancelRun() {
        guard isRunning, !isStoppingRun else { return }
        isStoppingRun = true
        runTask?.cancel()
        results = results.map { result in
            guard result.state == .running else { return result }
            var cancelled = result
            cancelled.state = .cancelled
            return cancelled
        }
    }

    func reset() {
        cancelRun()
        prompt = Self.defaultPrompt
        results = ToolCallingExperimentMode.allCases.map { ToolCallingModeRunResult.pending($0) }
        errorMessage = nil
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ToolCallingModeLabViewModel {
    var nonemptyPrompt: String? {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedPrompt.isEmpty ? nil : trimmedPrompt
    }

    func beginComparison(prompt: String) {
        cancelRun()

        let runID = UUID()
        activeRunID = runID
        isRunning = true
        isStoppingRun = false
        errorMessage = nil
        results = ToolCallingExperimentMode.allCases.map { ToolCallingModeRunResult.pending($0) }

        runTask = Task { @MainActor [weak self] in
            await self?.performComparison(prompt: prompt, id: runID)
        }
    }

    func performComparison(prompt: String, id: UUID) async {
        defer {
            if activeRunID == id {
                activeRunID = nil
                runTask = nil
                isRunning = false
                isStoppingRun = false
                activeMode = nil
            }
        }

        for mode in ToolCallingExperimentMode.allCases {
            guard !Task.isCancelled,
                  activeRunID == id,
                  self.prompt.trimmingCharacters(in: .whitespacesAndNewlines) == prompt else {
                return
            }

            activeMode = mode
            update(mode: mode) { result in
                result.state = .running
            }

            do {
                let result = try await run(mode: mode, prompt: prompt)
                try Task.checkCancellation()
                guard activeRunID == id, self.prompt.trimmingCharacters(in: .whitespacesAndNewlines) == prompt else {
                    return
                }
                replace(result)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                guard activeRunID == id else { return }
                update(mode: mode) { result in
                    result.state = .failed(error.localizedDescription)
                }
            }
        }
    }

    func run(mode: ToolCallingExperimentMode, prompt: String) async throws -> ToolCallingModeRunResult {
        let recorder = LocalReleaseRecordExecutionRecorder()
        let tool = LocalReleaseRecordTool(recorder: recorder)
        let session = LanguageModelSession(profile: ToolCallingModeProfile(tool: tool, mode: mode))
        let clock = ContinuousClock()
        let startedAt = clock.now
        let response = try await session.respond(
            to: prompt,
            metadata: ["foundation-lab-tool-mode": mode.rawValue]
        )
        let finishedAt = clock.now
        let localOutputs = await recorder.snapshot()

        return ToolCallingModeRunResult(
            mode: mode,
            state: .completed,
            modelResponse: response.content,
            elapsed: startedAt.duration(to: finishedAt),
            transcriptCalls: transcriptCalls(in: session.transcript),
            transcriptOutputs: transcriptOutputs(in: session.transcript),
            localToolOutputs: localOutputs
        )
    }

    func transcriptCalls(in transcript: Transcript) -> [String] {
        transcript.flatMap { entry -> [String] in
            guard case .toolCalls(let calls) = entry else { return [] }
            return calls.map { call in
                let query = try? LocalReleaseRecordQuery(call.arguments)
                let recordID = query?.recordID ?? String(localized: "Unreadable arguments")
                return "\(call.toolName)(recordID: \(recordID))"
            }
        }
    }

    func transcriptOutputs(in transcript: Transcript) -> [String] {
        transcript.compactMap { entry in
            guard case .toolOutput(let output) = entry else { return nil }
            let content = output.segments.textContentJoined() ?? String(localized: "No text output")
            return "\(output.toolName): \(content)"
        }
    }

    func update(
        mode: ToolCallingExperimentMode,
        mutation: (inout ToolCallingModeRunResult) -> Void
    ) {
        guard let index = results.firstIndex(where: { $0.mode == mode }) else { return }
        mutation(&results[index])
    }

    func replace(_ result: ToolCallingModeRunResult) {
        guard let index = results.firstIndex(where: { $0.mode == result.mode }) else { return }
        results[index] = result
    }

    func invalidateEditedPrompt() {
        cancelRun()
        results = ToolCallingExperimentMode.allCases.map { ToolCallingModeRunResult.pending($0) }
        errorMessage = nil
    }
}
#endif
