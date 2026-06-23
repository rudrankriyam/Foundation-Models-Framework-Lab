//
//  ReasoningLevelComparisonViewModel.swift
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
final class ReasoningLevelComparisonViewModel {
    static let defaultPrompt = "Plan a safe migration from callback-based networking to async/await in three ordered steps."

    var prompt = defaultPrompt {
        didSet {
            guard prompt != oldValue else { return }
            invalidateEditedPrompt()
        }
    }
    var results = ReasoningComparisonLevel.allCases.map { ReasoningComparisonResult.pending($0) }
    var isRunning = false
    var isStoppingRun = false
    var activeLevel: ReasoningComparisonLevel?
    var errorMessage: String?

    private var activeRunID: UUID?
    private var runTask: Task<Void, Never>?

    var hasResults: Bool {
        results.contains { $0.state != .pending }
    }

    var canRun: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isRunning
            && !isStoppingRun
            && readinessIssue == nil
    }

    var readinessIssue: String? {
        #if targetEnvironment(simulator)
        return String(
            localized: """
            Private Cloud Compute reasoning runs are unavailable in Simulator. \
            Run this lab on a supported Mac or physical device.
            """
        )
        #else
        let model = PrivateCloudComputeLanguageModel()

        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            return String(localized: "This device is not eligible for Private Cloud Compute.")
        case .unavailable(.systemNotReady):
            return String(localized: "Private Cloud Compute is not ready on this system.")
        @unknown default:
            return String(localized: "Private Cloud Compute is currently unavailable.")
        }

        guard !model.quotaUsage.isLimitReached else {
            return String(localized: "The Private Cloud Compute usage limit has been reached.")
        }

        guard model.capabilities.contains(.reasoning) else {
            return String(localized: "Private Cloud Compute does not report the reasoning capability on this runtime.")
        }

        return nil
        #endif
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
        results = ReasoningComparisonLevel.allCases.map { ReasoningComparisonResult.pending($0) }
        errorMessage = nil
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ReasoningLevelComparisonViewModel {
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
        results = ReasoningComparisonLevel.allCases.map { ReasoningComparisonResult.pending($0) }

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
                activeLevel = nil
            }
        }

        for level in ReasoningComparisonLevel.allCases {
            guard !Task.isCancelled,
                  activeRunID == id,
                  self.prompt.trimmingCharacters(in: .whitespacesAndNewlines) == prompt else {
                return
            }

            activeLevel = level
            update(level: level) { result in
                result.state = .running
            }

            do {
                let result = try await run(level: level, prompt: prompt)
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
                update(level: level) { result in
                    result.state = .failed(error.localizedDescription)
                }
            }
        }
    }

    func run(level: ReasoningComparisonLevel, prompt: String) async throws -> ReasoningComparisonResult {
        #if targetEnvironment(simulator)
        throw NSError(
            domain: "FoundationLab.ReasoningLevelComparison",
            code: 1,
            userInfo: [
                NSLocalizedDescriptionKey: String(
                    localized: "Private Cloud Compute reasoning runs are unavailable in Simulator."
                )
            ]
        )
        #else
        let model = PrivateCloudComputeLanguageModel()
        let session = LanguageModelSession(model: model)
        let clock = ContinuousClock()
        let startedAt = clock.now
        let response = try await session.respond(
            to: prompt,
            contextOptions: ContextOptions(reasoningLevel: level.frameworkValue),
            metadata: ["foundation-lab-reasoning-level": level.rawValue]
        )
        let finishedAt = clock.now

        return ReasoningComparisonResult(
            level: level,
            state: .completed,
            response: response.content,
            elapsed: startedAt.duration(to: finishedAt),
            inputTokens: response.usage.input.totalTokenCount,
            cachedInputTokens: response.usage.input.cachedTokenCount,
            outputTokens: response.usage.output.totalTokenCount,
            reasoningTokens: response.usage.output.reasoningTokenCount,
            totalTokens: response.usage.totalTokenCount
        )
        #endif
    }

    func update(
        level: ReasoningComparisonLevel,
        mutation: (inout ReasoningComparisonResult) -> Void
    ) {
        guard let index = results.firstIndex(where: { $0.level == level }) else { return }
        mutation(&results[index])
    }

    func replace(_ result: ReasoningComparisonResult) {
        guard let index = results.firstIndex(where: { $0.level == result.level }) else { return }
        results[index] = result
    }

    func invalidateEditedPrompt() {
        cancelRun()
        results = ReasoningComparisonLevel.allCases.map { ReasoningComparisonResult.pending($0) }
        errorMessage = nil
    }
}
#endif
