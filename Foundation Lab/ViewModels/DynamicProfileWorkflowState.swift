//
//  DynamicProfileWorkflowState.swift
//  FoundationLab
//

import Observation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@MainActor
@Observable
final class DynamicProfileWorkflowState {
    var stage = DynamicProfileWorkflowStage.inspect
    var reviewRuntime = DynamicProfileReviewRuntime.privateCloudCompute
    private(set) var instructionEvents: [DynamicProfileInstructionEvent] = []

    func recordInstructionEvent(
        _ kind: DynamicProfileInstructionEvent.Kind,
        stage: DynamicProfileWorkflowStage,
        runtime: DynamicProfileReviewRuntime
    ) {
        instructionEvents.append(
            DynamicProfileInstructionEvent(
                sequence: instructionEvents.count + 1,
                kind: kind,
                stage: stage,
                runtime: runtime
            )
        )
    }

    func clearInstructionEvents() {
        instructionEvents = []
    }
}
