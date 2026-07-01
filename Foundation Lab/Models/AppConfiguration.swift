//
//  AppConfiguration.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 11/7/25.
//

import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit

/// Centralized configuration constants for the app
enum AppConfiguration {
    /// Token management configuration
    enum TokenManagement {
        /// Fallback maximum tokens when dynamic context size is unavailable
        static let defaultMaxTokens = 4096

        /// Threshold percentage (0.0-1.0) at which to start applying sliding window
        static let windowThreshold = 0.75

        /// Target window size in tokens after applying sliding window
        static let targetWindowSize = 2000

        /// Fetches the real context size from the model when available,
        /// falling back to the default of 4096.
        static func contextSize(
            for model: SystemLanguageModel = .default
        ) async -> Int {
            #if compiler(>=6.3)
            return model.contextSize
            #else
            return defaultMaxTokens
            #endif
        }

        static func contextSize(
            modelUseCase: FoundationModelUseCase = .general,
            guardrails: FoundationModelGuardrails = .default
        ) async -> Int {
            let model = SystemLanguageModel(
                useCase: modelUseCase.foundationModelsValue,
                guardrails: guardrails.foundationModelsValue
            )
            return await contextSize(for: model)
        }
    }

    /// Health module configuration
    enum Health {
        /// Session timeout interval (1 hour)
        static let sessionTimeout: TimeInterval = 3600
    }
}
