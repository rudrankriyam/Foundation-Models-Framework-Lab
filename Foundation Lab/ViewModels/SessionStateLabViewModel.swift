//
//  SessionStateLabViewModel.swift
//  FoundationLab
//

import Foundation
import FoundationModels
import Observation

#if canImport(FoundationModels, _version: 2.2)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class SessionStateLabViewModel {
    static let defaultPrompt = "Plan a quiet Saturday in Kyoto."

    var prompt = defaultPrompt
    private(set) var turns: [SessionStateLabTurn] = []
    private(set) var latestReportedRemaining: Int?
    private(set) var isRunning = false
    private(set) var isStopping = false
    var errorMessage: String?

    @ObservationIgnored
    private var ledger = SessionStateLedger()
    @ObservationIgnored
    private var session: LanguageModelSession?
    @ObservationIgnored
    private var activeRunID: UUID?
    @ObservationIgnored
    private var runTask: Task<Void, Never>?

    var replyBudget: Int { SessionStateBudgetProfile.replyBudget }

    var isExecuting: Bool {
        isRunning || isStopping
    }

    var canRun: Bool {
        !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !isExecuting
            && readinessIssue == nil
    }

    var readinessIssue: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return String(localized: "This device is not eligible for the on-device system language model.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "Apple Intelligence is not enabled.")
        case .unavailable(.modelNotReady):
            return String(localized: "The on-device system language model is not ready.")
        @unknown default:
            return String(localized: "The on-device system language model is unavailable.")
        }
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

    func startNewSession() {
        guard !isExecuting else { return }
        prompt = Self.defaultPrompt
        turns = []
        latestReportedRemaining = nil
        errorMessage = nil
        session = nil
        ledger = SessionStateLedger()
    }

    var codeExample: String {
        """
        import FoundationModels

        struct BudgetProfile: LanguageModelSession.DynamicProfile {
            // Owned by this profile and kept for the session's lifetime.
            @SessionState private var remainingReplies = 3

            var body: some LanguageModelSession.DynamicProfile {
                if remainingReplies > 0 {
                    ReplyProfile(remainingReplies: $remainingReplies)
                } else {
                    LanguageModelSession.Profile {
                        Instructions("Say the reply budget is spent.")
                    }
                }
            }
        }

        struct ReplyProfile: LanguageModelSession.DynamicProfile {
            @SessionBinding private var remainingReplies: Int

            init(remainingReplies: SessionBinding<Int>) {
                _remainingReplies = remainingReplies
            }

            var body: some LanguageModelSession.DynamicProfile {
                LanguageModelSession.Profile {
                    BudgetInstructions(remainingReplies: $remainingReplies)
                }
                .onResponse { remainingReplies -= 1 }
            }
        }

        struct BudgetInstructions: DynamicInstructions {
            @SessionBinding private var remainingReplies: Int

            init(remainingReplies: SessionBinding<Int>) {
                _remainingReplies = remainingReplies
            }

            var body: some DynamicInstructions {
                Instructions("Replies remaining, including this one: \\(remainingReplies).")
            }
        }

        // Contrast: a session property is keyed on SessionPropertyValues,
        // and the app can read or write it through session.properties.
        extension SessionPropertyValues {
            @SessionPropertyEntry var appVisibleReplies = 0
        }

        let session = LanguageModelSession(profile: BudgetProfile())
        try await session.respond(to: "Plan a quiet Saturday in Kyoto.")
        session.properties.appVisibleReplies // reachable from the app
        // remainingReplies stays in the profile tree; children get it through $remainingReplies.
        """
    }
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension SessionStateLabViewModel {
    func currentSession(ledger: SessionStateLedger) -> LanguageModelSession {
        if let session {
            return session
        }

        let newSession = LanguageModelSession(profile: SessionStateBudgetProfile(ledger: ledger))
        session = newSession
        return newSession
    }

    func performRun(prompt: String, id: UUID) async {
        let currentLedger = ledger
        let modelSession = currentSession(ledger: currentLedger)
        let previousCount = await currentLedger.snapshot().count
        let clock = ContinuousClock()
        let startedAt = clock.now

        defer {
            if activeRunID == id {
                activeRunID = nil
                runTask = nil
                isRunning = false
                isStopping = false
            }
        }

        do {
            let response = try await modelSession.respond(to: prompt)
            let observations = await currentLedger.snapshot()
            guard activeRunID == id else { return }
            latestReportedRemaining = observations.last?.remainingReplies

            turns.append(
                SessionStateLabTurn(
                    number: turns.count + 1,
                    prompt: prompt,
                    response: response.content,
                    observations: Array(observations.dropFirst(previousCount)),
                    elapsed: startedAt.duration(to: clock.now)
                )
            )
        } catch is CancellationError {
            await refreshLatestReportedRemaining(from: currentLedger, id: id)
        } catch {
            await refreshLatestReportedRemaining(from: currentLedger, id: id)
            guard !Task.isCancelled, activeRunID == id else { return }
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    func refreshLatestReportedRemaining(from ledger: SessionStateLedger, id: UUID) async {
        let latest = await ledger.snapshot().last?.remainingReplies
        guard activeRunID == id else { return }
        latestReportedRemaining = latest
    }
}
#endif
