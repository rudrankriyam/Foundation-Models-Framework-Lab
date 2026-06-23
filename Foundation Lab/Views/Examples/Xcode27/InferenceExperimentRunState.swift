//
//  InferenceExperimentRunState.swift
//  FoundationLab
//

nonisolated enum InferenceExperimentRunState: Equatable, Sendable {
    case pending
    case running
    case completed
    case cancelled
    case failed(String)
}
