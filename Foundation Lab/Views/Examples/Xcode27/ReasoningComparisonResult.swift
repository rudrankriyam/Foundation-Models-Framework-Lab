//
//  ReasoningComparisonResult.swift
//  FoundationLab
//

import Foundation

nonisolated struct ReasoningComparisonResult: Identifiable, Sendable {
    let level: ReasoningComparisonLevel
    var state: InferenceExperimentRunState
    var response: String?
    var elapsed: Duration?
    var inputTokens: Int?
    var cachedInputTokens: Int?
    var outputTokens: Int?
    var reasoningTokens: Int?
    var totalTokens: Int?

    var id: ReasoningComparisonLevel { level }

    static func pending(_ level: ReasoningComparisonLevel) -> Self {
        ReasoningComparisonResult(level: level, state: .pending)
    }
}
