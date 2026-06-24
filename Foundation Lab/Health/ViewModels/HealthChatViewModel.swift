//
//  HealthChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit
import Observation
import OSLog
import SwiftData
import SwiftUI

@MainActor
@Observable
final class HealthChatViewModel {

    // MARK: - Constants

    private let sessionTimeout: TimeInterval = AppConfiguration.Health.sessionTimeout
    private let logger = Logger(subsystem: "com.foundationlab.health", category: "HealthChatViewModel")

    // MARK: - Published Properties

    var isLoading: Bool = false
    var isSummarizing: Bool = false
    var sessionCount: Int = 1
    var currentHealthMetrics: [MetricType: Double] = [:]
    var errorMessage: String?
    var showError = false

    // MARK: - Token Usage Tracking

    private(set) var currentTokenCount: Int = 0
    private(set) var currentTokenUsage: ModelTokenUsage?
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession
    private var configurationTask: Task<Void, Never>?
    private var modelContext: ModelContext?
    private var responseTask: Task<Void, Never>?
    private let healthDataManager: HealthDataManager
    private let languageModel = SystemLanguageModel.default
    private let conversationEngine: FoundationLabConversationEngine

    // MARK: - Tools

    private let tools: [any Tool] = [HealthDataTool()]

    // MARK: - Initialization

    init(healthDataManager: HealthDataManager? = nil) {
        self.healthDataManager = healthDataManager ?? .shared

        let configuration = FoundationLabConversationConfiguration(
            baseInstructions: Self.baseInstructions,
            summaryInstructions: """
            Preserve the HealthKit measurements, date ranges, unavailable fields, and user questions already discussed.
            Do not add interpretations, goals, diagnoses, or advice.
            """,
            summaryPromptPreamble: """
            Summarize this Health data conversation using only information already present in the transcript:
            """,
            conversationUserLabel: String(localized: "User:"),
            conversationAssistantLabel: String(localized: "Foundation Models:"),
            continuationNote: "Continue the conversation naturally, referencing this context when relevant.",
            overflowResetMessage: """
            This conversation reached its context limit, so a fresh session has started.
            Please send your last message again.
            """,
            modelUseCase: .general,
            guardrails: .default,
            tools: tools,
            enableSlidingWindow: false,
            defaultMaxContextSize: AppConfiguration.TokenManagement.defaultMaxTokens
        )
        let engine = FoundationLabConversationEngine(configuration: configuration)
        self.conversationEngine = engine
        self.session = engine.session

        engine.onStateChange = { [weak self] in
            self?.syncConversationState()
        }
        syncConversationState()

        let configuredLanguageModel = languageModel
        configurationTask = Task { [weak self, configuredLanguageModel] in
            let contextSize = await AppConfiguration.TokenManagement.contextSize(for: configuredLanguageModel)
            guard !Task.isCancelled, let self else { return }
            conversationEngine.setMaxContextSize(contextSize)
            syncConversationState()
        }
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    // MARK: - Public Methods

    func sendMessage(_ content: String) {
        guard !isLoading else { return }
        isLoading = true
        responseTask = Task { [weak self] in
            await self?.performSendMessage(content)
        }
    }

    private func performSendMessage(_ content: String) async {
        defer {
            isLoading = false
            responseTask = nil
        }

        do {
            await saveMessageToSession(content, isFromUser: true)

            let responseText = try await conversationEngine.sendStreamingMessage(content)
            syncConversationState()

            if !responseText.isEmpty {
                await saveMessageToSession(responseText, isFromUser: false)
            }

        } catch is CancellationError {
            return
        } catch {
            logger.error("Failed to generate response: \(error.localizedDescription, privacy: .public)")
            let errorText = FoundationModelsErrorHandler.handleError(error)
            errorMessage = errorText
            showError = true
            await saveMessageToSession(errorText, isFromUser: false)
        }
    }

    func clearChat() {
        responseTask?.cancel()
        responseTask = nil
        conversationEngine.clear()
        errorMessage = nil
        showError = false
        syncConversationState()
    }

    func tearDown() {
        configurationTask?.cancel()
        configurationTask = nil
        responseTask?.cancel()
        responseTask = nil
        conversationEngine.cancelActiveResponse()
    }

    func loadInitialHealthData() async {
        errorMessage = nil
        showError = false

        do {
            if !healthDataManager.isAuthorized {
                try await healthDataManager.requestAuthorization()
            }

            guard !Task.isCancelled else { return }
            try await healthDataManager.fetchTodayHealthData()
        } catch is CancellationError {
            return
        } catch {
            logger.error("Failed to load health data: \(error.localizedDescription, privacy: .public)")
            let errorText = FoundationModelsErrorHandler.handleError(error)
            errorMessage = errorText
            showError = true
        }

        currentHealthMetrics = healthDataManager.currentMetrics
    }
}

private extension HealthChatViewModel {
    static let baseInstructions = """
    You help users understand HealthKit measurements that Foundation Lab can read.
    Use the HealthDataTool whenever a response depends on the user's measurements.
    Never invent measurements, trends, correlations, diagnoses, or predictions.
    Never infer a goal, score, or health status from the available measurements.
    If requested data is unavailable, say so plainly and identify which measurement is missing.
    Keep summaries factual and distinguish today's values, latest values, and weekly aggregates.
    Do not provide medical advice. Suggest professional care when a request requires medical interpretation.
    """

    func syncConversationState() {
        session = conversationEngine.session
        currentTokenCount = conversationEngine.currentTokenCount
        currentTokenUsage = conversationEngine.currentTokenUsage
        maxContextSize = conversationEngine.maxContextSize
        isSummarizing = conversationEngine.isSummarizing
        sessionCount = conversationEngine.sessionCount
    }

}

@MainActor
private extension HealthChatViewModel {
    func saveMessageToSession(_ content: String, isFromUser: Bool) async {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<HealthSession>(
            sortBy: [SortDescriptor<HealthSession>(\.startDate, order: .reverse)]
        )

        do {
            let sessions = try modelContext.fetch(descriptor)
            let activeSession: HealthSession

            if let existingSession = sessions.first,
               existingSession.startDate.timeIntervalSinceNow > -sessionTimeout {
                activeSession = existingSession
            } else {
                activeSession = HealthSession(sessionType: .coaching)
                modelContext.insert(activeSession)
            }

            let message = BuddyMessage(content: content, isFromUser: isFromUser)
            activeSession.messages.append(message)

            try modelContext.save()
        } catch {
            logger.error("Failed to save message to session: \(error.localizedDescription, privacy: .public)")
        }
    }

}
