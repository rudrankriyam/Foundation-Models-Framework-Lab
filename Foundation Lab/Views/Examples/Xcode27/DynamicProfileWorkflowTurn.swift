//
//  DynamicProfileWorkflowTurn.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated struct DynamicProfileWorkflowTurn: Identifiable, Sendable {
    let id = UUID()
    let stage: DynamicProfileWorkflowStage
    let runtime: DynamicProfileReviewRuntime
    let prompt: String
    let response: String
    let toolOutputs: [String]
    let elapsed: Duration
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningTokens: Int
    let totalTokens: Int
    let transcriptEntryCount: Int
}
#endif
