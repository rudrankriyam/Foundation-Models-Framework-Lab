//
//  ExampleExecutor.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
import SwiftUI

/// A reusable helper class for executing example operations
@MainActor
@Observable
final class ExampleExecutor {
    var isRunning = false
    var result: String = ""
    var errorMessage: String?
    var successMessage: String?
    var promptHistory: [String] = []

    /// Token count from the last operation. Updated after each execution.
    private(set) var lastTokenCount: Int?
    private let generateTextUseCase = GenerateTextUseCase()
    private let generateBookRecommendationUseCase = GenerateBookRecommendationUseCase()
    private let streamTextGenerationUseCase = StreamTextGenerationUseCase()

    /// Executes a basic language model operation
    func executeBasic(
        prompt: String,
        instructions: String? = nil,
        successMessage: String? = nil,
        guardrails: FoundationLabGuardrails = .default
    ) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "Please enter a valid prompt")
            return
        }

        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        self.successMessage = nil
        result = ""
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let response = try await generateTextUseCase.execute(
                TextGenerationRequest(
                    prompt: prompt,
                    systemPrompt: instructions,
                    guardrails: guardrails,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            try Task.checkCancellation()
            result = response.content
            lastTokenCount = response.metadata.tokenCount

            if let successMessage = successMessage {
                self.successMessage = successMessage
            }
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
            self.successMessage = nil
        }
    }

    /// Executes a structured data generation operation
    func executeStructured<T: Generable & Sendable>(
        prompt: String,
        type: T.Type,
        instructions: String? = nil,
        formatter: @escaping (T) -> String
    ) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "Please enter a valid prompt")
            return
        }

        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        successMessage = nil
        result = ""
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let response = try await GenerateStructuredDataUseCase<T>().execute(
                StructuredGenerationRequest<T>(
                    prompt: prompt,
                    systemPrompt: instructions,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            try Task.checkCancellation()

            result = formatter(response.output)
            lastTokenCount = response.metadata.tokenCount
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    /// Executes the shared book recommendation capability.
    func executeBookRecommendation(
        prompt: String,
        systemPrompt: String? = nil
    ) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "Please enter a valid prompt")
            return
        }

        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        successMessage = nil
        result = ""
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let response = try await generateBookRecommendationUseCase.execute(
                GenerateBookRecommendationRequest(
                    prompt: prompt,
                    systemPrompt: systemPrompt,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            try Task.checkCancellation()

            let book = response.recommendation
            result = """
            📚 Title: \(book.title)
            ✍️ Author: \(book.author)
            🏷️ Genre: \(book.genre.displayName)

            📖 Description:
            \(book.description)
            """
            lastTokenCount = response.metadata.tokenCount
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    /// Executes a streaming operation
    func executeStreaming(
        prompt: String,
        instructions: String? = nil,
        onPartialResult: @escaping @MainActor @Sendable (String) -> Void
    ) async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = String(localized: "Please enter a valid prompt")
            return
        }

        isRunning = true
        defer { isRunning = false }
        errorMessage = nil
        successMessage = nil
        result = ""
        lastTokenCount = nil

        addToHistory(prompt)

        do {
            let response = try await streamTextGenerationUseCase.execute(
                StreamingTextGenerationRequest(
                    prompt: prompt,
                    systemPrompt: instructions,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            ) { [weak self] partialText in
                guard let self else { return }
                await self.applyStreamingUpdate(partialText, onPartialResult: onPartialResult)
            }
            try Task.checkCancellation()

            result = response.content
            lastTokenCount = response.metadata.tokenCount
        } catch is CancellationError {
            return
        } catch {
            errorMessage = FoundationModelsErrorHandler.handleError(error)
        }
    }

    @MainActor
    private func applyStreamingUpdate(
        _ partialText: String,
        onPartialResult: @MainActor @Sendable (String) -> Void
    ) {
        result = partialText
        onPartialResult(partialText)
    }

    /// Clears all state
    func clear() {
        isRunning = false
        result = ""
        errorMessage = nil
        successMessage = nil
        lastTokenCount = nil
    }

    /// Clears all state including prompt history
    func clearAll() {
        clear()
        promptHistory = []
    }

    /// Adds a prompt to history
    private func addToHistory(_ prompt: String) {
        promptHistory.removeAll { $0 == prompt }
        promptHistory.insert(prompt, at: 0)
        if promptHistory.count > 10 {
            promptHistory = Array(promptHistory.prefix(10))
        }
    }

    func storeLastTokenCount(_ count: Int?) {
        lastTokenCount = count
    }
}
