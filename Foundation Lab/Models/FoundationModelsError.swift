//
//  FoundationModelsError.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationLabCore
import FoundationModels

/// Custom error types for Foundation Models operations
nonisolated enum FoundationModelsError: LocalizedError, Sendable {
    case sessionCreationFailed
    case responseGenerationFailed(String)
    case toolCallFailed(String)
    case streamingFailed(String)
    case modelUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .sessionCreationFailed:
            return String(localized: "Failed to create language model session")
        case .responseGenerationFailed(let message):
            return String(localized: "Response generation failed: \(message)")
        case .toolCallFailed(let message):
            return String(localized: "Tool call failed: \(message)")
        case .streamingFailed(let message):
            return String(localized: "Streaming failed: \(message)")
        case .modelUnavailable(let message):
            return String(localized: "Model unavailable: \(message)")
        }
    }
}

/// Helper for handling LanguageModelSession errors
struct FoundationModelsErrorHandler: Sendable {
    static func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .exceededContextWindowSize(let context):
            return String(localized: "Context window exceeded: \(context.debugDescription)")
        case .assetsUnavailable(let context):
            return String(localized: "Model assets unavailable: \(context.debugDescription)")
        case .guardrailViolation(let context):
            return String(localized: "Content policy violation: \(context.debugDescription)")
        case .decodingFailure(let context):
            return String(localized: "Failed to decode response: \(context.debugDescription)")
        case .unsupportedGuide(let context):
            return String(localized: "Unsupported generation guide: \(context.debugDescription)")
        case .unsupportedLanguageOrLocale(let context):
            return String(localized: "Unsupported language/locale: \(context.debugDescription)")
        case .rateLimited(let context):
            return String(localized: "Rate limited: \(context.debugDescription)")
        case .concurrentRequests(let context):
            return String(localized: "Too many concurrent requests: \(context.debugDescription)")
            // Refusal is async throws
        case .refusal(_, let context):
            return String(localized: "Model refused to respond: \(context.debugDescription)")
        @unknown default:
            return String(localized: "Unknown generation error")
        }
    }

    static func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
        return String(localized: "Tool '\(error.tool.name)' failed: \(error.underlyingError.localizedDescription)")
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func handlePrivateCloudComputeError(_ error: PrivateCloudComputeLanguageModel.Error) -> String {
        switch error {
        case .networkFailure(let context):
            return String(localized: "PCC network failure: \(context.debugDescription)")
        case .quotaLimitReached(let context):
            return String(localized: "PCC quota limit reached: \(context.debugDescription)")
        case .serviceUnavailable(let context):
            return String(localized: "PCC service unavailable: \(context.debugDescription)")
        @unknown default:
            return String(localized: "PCC failed with an unknown service error.")
        }
    }
    #endif

    /// Consolidates error handling for LanguageModelSession operations
    static func handleError(_ error: Error) -> String {
        if let generationError = error as? LanguageModelSession.GenerationError {
            return handleGenerationError(generationError)
        }

        if let toolCallError = error as? LanguageModelSession.ToolCallError {
            return handleToolCallError(toolCallError)
        }

        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *),
           let privateCloudComputeError = error as? PrivateCloudComputeLanguageModel.Error {
            return handlePrivateCloudComputeError(privateCloudComputeError)
        }
        #endif

        if let coreError = error as? FoundationLabCoreError {
            return coreError.localizedDescription
        }

        if let customError = error as? FoundationModelsError {
            return customError.localizedDescription
        }

        return String(localized: "Unexpected error: \(error.localizedDescription)")
    }
}
