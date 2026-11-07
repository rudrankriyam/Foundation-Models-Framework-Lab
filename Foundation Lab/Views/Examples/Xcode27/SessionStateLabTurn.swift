//
//  SessionStateLabTurn.swift
//  FoundationLab
//

import Foundation

nonisolated struct SessionStateLabTurn: Identifiable, Sendable {
    let id = UUID()
    let number: Int
    let prompt: String
    let response: String
    let observations: [SessionStateObservation]
    let elapsed: Duration

    var remainingBefore: Int? {
        observations.first { $0.phase != .response }?.remainingReplies
    }

    var remainingAfter: Int? {
        observations.last?.remainingReplies
    }

    var usedSpentBudgetProfile: Bool {
        observations.contains { $0.phase == .budgetSpent }
    }
}
