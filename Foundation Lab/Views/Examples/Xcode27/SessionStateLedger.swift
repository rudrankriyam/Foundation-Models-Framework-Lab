//
//  SessionStateLedger.swift
//  FoundationLab
//

actor SessionStateLedger {
    private var observations: [SessionStateObservation] = []

    func record(_ phase: SessionStateObservation.Phase, remainingReplies: Int) {
        observations.append(SessionStateObservation(phase: phase, remainingReplies: remainingReplies))
    }

    func snapshot() -> [SessionStateObservation] {
        observations
    }
}
