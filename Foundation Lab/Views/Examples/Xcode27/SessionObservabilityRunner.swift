//
//  SessionObservabilityRunner.swift
//  FoundationLab
//

import Foundation

#if compiler(>=6.4)
import FoundationModels
#endif

enum SessionObservabilityRunner {
    enum RunError: LocalizedError {
        case modelUnavailable
        case toolCallingUnavailable
        case emptyTranscript

        var errorDescription: String? {
            switch self {
            case .modelUnavailable:
                String(localized: "The on-device system language model is unavailable.")
            case .toolCallingUnavailable:
                String(localized: "This system language model does not support tool calling, which this lab requires.")
            case .emptyTranscript:
                String(localized: "The session completed without observable transcript entries.")
            }
        }
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    static func run(
        prompt: String,
        labIdentifier: String,
        requestsReasoning: Bool = false
    ) async throws -> SessionTranscriptSnapshot {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            throw RunError.modelUnavailable
        }
        guard model.capabilities.contains(.toolCalling) else {
            throw RunError.toolCallingUnavailable
        }

        let reasoningLevel: ContextOptions.ReasoningLevel? = if requestsReasoning,
                                                               model.capabilities.contains(.reasoning) {
            .moderate
        } else {
            nil
        }

        let session = LanguageModelSession(
            profile: SessionObservabilityProfile(reasoningLevel: reasoningLevel)
        )
        _ = try await session.respond(
            to: prompt,
            metadata: ["foundationLab.example": labIdentifier]
        )
        try Task.checkCancellation()

        let snapshot = SessionTranscriptSnapshot(transcript: session.transcript)
        guard !snapshot.entries.isEmpty else {
            throw RunError.emptyTranscript
        }
        return snapshot
    }
    #endif
}
