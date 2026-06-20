//
//  HealthChatViewModel.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
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

    // MARK: - Token Usage Tracking

    private(set) var currentTokenCount: Int = 0
    private(set) var maxContextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    var tokenUsageFraction: Double {
        guard maxContextSize > 0 else { return 0 }
        return min(1.0, Double(currentTokenCount) / Double(maxContextSize))
    }

    // MARK: - Public Properties

    private(set) var session: LanguageModelSession
    private var modelContext: ModelContext?
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
            You are an expert at summarizing health coaching conversations.
            Create comprehensive summaries that preserve all health metrics discussed,
            goals set, and advice given.
            """,
            summaryPromptPreamble: """
            Please summarize the following health coaching conversation.
            Include all health metrics discussed, goals mentioned, advice given, and user's health concerns:
            """,
            conversationUserLabel: String(localized: "User:"),
            conversationAssistantLabel: String(localized: "Health AI:"),
            continuationNote: "Continue the conversation naturally, referencing this context when relevant.",
            overflowResetMessage: """
            I need to start a fresh conversation to keep your health coaching accurate.
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

        Task {
            let contextSize = await AppConfiguration.TokenManagement.contextSize(for: languageModel)
            conversationEngine.setMaxContextSize(contextSize)
            syncConversationState()
        }
    }

    func setModelContext(_ context: ModelContext) {
        modelContext = context
    }

    // MARK: - Public Methods

    func sendMessage(_ content: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            await saveMessageToSession(content, isFromUser: true)

            let responseText = try await conversationEngine.sendStreamingMessage(content)
            syncConversationState()

            if !responseText.isEmpty {
                await saveMessageToSession(responseText, isFromUser: false)
            }

            if shouldGenerateInsight(from: responseText) {
                await generateHealthInsight(from: responseText)
            }
        } catch is CancellationError {
            return
        } catch {
            logger.error("Failed to generate response: \(error.localizedDescription, privacy: .public)")
            let errorText = FoundationModelsErrorHandler.handleError(error)
            await saveMessageToSession(errorText, isFromUser: false)
        }
    }

    func clearChat() {
        conversationEngine.clear()
        syncConversationState()
    }

    func tearDown() {
        conversationEngine.cancelActiveResponse()
    }

    func loadInitialHealthData() async {
        do {
            try await healthDataManager.fetchTodayHealthData()
        } catch {
            logger.error("Failed to load health data: \(error.localizedDescription, privacy: .public)")
            await saveMessageToSession(
                FoundationModelsErrorHandler.handleError(error),
                isFromUser: false
            )
        }

        currentHealthMetrics = [
            .steps: healthDataManager.todaySteps,
            .heartRate: healthDataManager.currentHeartRate,
            .sleep: healthDataManager.lastNightSleep,
            .activeEnergy: healthDataManager.todayActiveEnergy,
            .distance: healthDataManager.todayDistance
        ]
    }
}

private extension HealthChatViewModel {
    static let baseInstructions = """
    You are a friendly and knowledgeable health coach AI assistant.
    Use the HealthDataTool whenever a response depends on the user's measurements.
    Never invent measurements, trends, correlations, diagnoses, or predictions.
    If the requested data is unavailable, say so plainly and suggest what the user can check next.
    Explain that health information is educational and not a substitute for professional medical advice when appropriate.
    Based only on available health data, provide personalized, encouraging responses.
    Be supportive and celebrate small wins. Use emojis occasionally.
    """

    func syncConversationState() {
        session = conversationEngine.session
        currentTokenCount = conversationEngine.currentTokenCount
        maxContextSize = conversationEngine.maxContextSize
        isSummarizing = conversationEngine.isSummarizing
        sessionCount = conversationEngine.sessionCount
    }

    func shouldGenerateInsight(from response: String) -> Bool {
        let insightKeywords = ["goal", "achieve", "progress", "improve", "recommend", "suggest", "tip", "advice"]
        return insightKeywords.contains { response.lowercased().contains($0) }
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

    func generateHealthInsight(from response: String) async {
        guard let modelContext else { return }

        let insight = HealthInsight(
            title: "AI Health Tip",
            content: response,
            category: .recommendation,
            priority: .medium,
            relatedMetrics: []
        )

        modelContext.insert(insight)

        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save health insight: \(error.localizedDescription, privacy: .public)")
        }
    }
}
