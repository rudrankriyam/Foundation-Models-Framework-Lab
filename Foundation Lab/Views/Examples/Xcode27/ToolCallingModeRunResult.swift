//
//  ToolCallingModeRunResult.swift
//  FoundationLab
//

import Foundation

nonisolated struct ToolCallingModeRunResult: Identifiable, Sendable {
    let mode: ToolCallingExperimentMode
    var state: InferenceExperimentRunState
    var modelResponse: String?
    var elapsed: Duration?
    var transcriptCalls: [String]
    var transcriptOutputs: [String]
    var localToolOutputs: [String]

    var id: ToolCallingExperimentMode { mode }

    static func pending(_ mode: ToolCallingExperimentMode) -> Self {
        ToolCallingModeRunResult(
            mode: mode,
            state: .pending,
            transcriptCalls: [],
            transcriptOutputs: [],
            localToolOutputs: []
        )
    }
}
