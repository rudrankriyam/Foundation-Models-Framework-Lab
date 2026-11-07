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
}
