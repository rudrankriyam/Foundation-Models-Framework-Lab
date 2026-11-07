//
//  SessionStateObservation.swift
//  FoundationLab
//

nonisolated struct SessionStateObservation: Sendable {
    enum Phase: Sendable {
        case prompt
        case response
        case budgetSpent
    }

    let phase: Phase
    let remainingReplies: Int
}
