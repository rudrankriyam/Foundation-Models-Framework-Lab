//
//  FoundationModelsError.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationLabCore
import FoundationModelsKit
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
            return String(localized: "The model session couldn’t start. Check model availability and try again.")
        case .responseGenerationFailed(let message):
            return String(localized: "The model couldn’t generate a response. \(message)")
        case .toolCallFailed(let message):
            return String(localized: "The tool couldn’t finish. \(message)")
        case .streamingFailed(let message):
            return String(localized: "The response stream ended unexpectedly. \(message)")
        case .modelUnavailable(let message):
            return String(localized: "The model isn’t available. \(message)")
        }
    }
}

/// Helper for handling LanguageModelSession errors
struct FoundationModelsErrorHandler: Sendable {
    static func handleGenerationError(_ error: LanguageModelSession.GenerationError) -> String {
        switch error {
        case .exceededContextWindowSize(let context):
            return detailedMessage(
                String(localized: "This session ran out of context. Shorten the prompt or start a new experiment."),
                details: context.debugDescription
            )
        case .assetsUnavailable(let context):
            return detailedMessage(
                String(localized: "The model isn’t ready. Wait for Apple Intelligence to finish downloading, then try again."),
                details: context.debugDescription
            )
        case .guardrailViolation(let context):
            return detailedMessage(
                String(localized: "The request or response triggered a safety guardrail. Revise the prompt and try again."),
                details: context.debugDescription
            )
        case .decodingFailure(let context):
            return detailedMessage(
                String(localized: "The response didn’t match the requested schema. Review the schema and generation guides."),
                details: context.debugDescription
            )
        case .unsupportedGuide(let context):
            return detailedMessage(
                String(localized: "The model doesn’t support one of these generation guides. Simplify or remove the guide."),
                details: context.debugDescription
            )
        case .unsupportedLanguageOrLocale(let context):
            return detailedMessage(
                String(localized: "The model doesn’t support this language or locale. Choose a supported language and try again."),
                details: context.debugDescription
            )
        case .rateLimited(let context):
            return detailedMessage(
                String(localized: "The model is receiving too many requests. Wait a moment, then try again."),
                details: context.debugDescription
            )
        case .concurrentRequests(let context):
            return detailedMessage(
                String(localized: "Another request is already running in this session. Wait for it to finish or stop it first."),
                details: context.debugDescription
            )
        case .refusal(_, let context):
            return detailedMessage(
                String(localized: "The model declined this request. Revise the prompt or try a different task."),
                details: context.debugDescription
            )
        @unknown default:
            return String(localized: "The model couldn’t generate a response. Try again or start a new experiment.")
        }
    }

    static func handleToolCallError(_ error: LanguageModelSession.ToolCallError) -> String {
        return String(
            localized: "The \(error.tool.name) tool couldn’t finish. \(error.underlyingError.localizedDescription)"
        )
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func handlePrivateCloudComputeError(_ error: PrivateCloudComputeLanguageModel.Error) -> String {
        switch error {
        case .networkFailure(let context):
            return detailedMessage(
                String(localized: "Private Cloud Compute couldn’t connect. Check the network and try again."),
                details: context.debugDescription
            )
        case .quotaLimitReached(let context):
            return detailedMessage(
                String(localized: "Private Cloud Compute has reached its request limit. Wait before trying again."),
                details: context.debugDescription
            )
        case .serviceUnavailable(let context):
            return detailedMessage(
                String(localized: "Private Cloud Compute is temporarily unavailable. Try again later."),
                details: context.debugDescription
            )
        @unknown default:
            return String(localized: "Private Cloud Compute couldn’t complete the request. Try again later.")
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

        return String(localized: "Something went wrong. \(error.localizedDescription)")
    }

    private static func detailedMessage(_ message: String, details: String) -> String {
        "\(message) \(String(localized: "Details:")) \(details)"
    }
}
