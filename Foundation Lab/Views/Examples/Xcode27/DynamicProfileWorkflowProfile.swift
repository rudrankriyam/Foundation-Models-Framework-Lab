//
//  DynamicProfileWorkflowProfile.swift
//  FoundationLab
//

import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SessionPropertyValues {
    @SessionPropertyEntry
    var dynamicWorkflowRequiresToolCall = false
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileWorkflowProfile: LanguageModelSession.DynamicProfile {
    let state: DynamicProfileWorkflowState
    let tool: LocalReleaseRecordTool
    let privateCloudComputeModel: PrivateCloudComputeLanguageModel

    @SessionProperty(\.dynamicWorkflowRequiresToolCall)
    private var requiresInspectionToolCall

    var body: some LanguageModelSession.DynamicProfile {
        switch state.stage {
        case .inspect:
            LanguageModelSession.Profile {
                lifecycleGroup(stage: .inspect, runtime: .onDevice) {
                    Instructions(
                        """
                        Inspect the bundled sample release record. Call the read-only tool before answering, use only its output \
                        as release evidence, and label anything else as unknown. Never imply that the tool reads GitHub or a real \
                        build.
                        """
                    )
                    tool
                }
            }
            .model(SystemLanguageModel.default)
            .temperature(0.1)
            .maximumResponseTokens(320)
            .toolCallingMode(requiresInspectionToolCall ? .required : .allowed)
            .onToolCall {
                requiresInspectionToolCall = false
            }

        case .review:
            if state.reviewRuntime == .privateCloudCompute {
                LanguageModelSession.Profile {
                    lifecycleGroup(stage: .review, runtime: .privateCloudCompute) {
                        reviewInstructions
                    }
                }
                .model(privateCloudComputeModel)
                .reasoningLevel(.moderate)
                .temperature(0.1)
                .maximumResponseTokens(480)
            } else {
                LanguageModelSession.Profile {
                    lifecycleGroup(stage: .review, runtime: .onDevice) {
                        reviewInstructions
                    }
                }
                .model(SystemLanguageModel.default)
                .temperature(0.1)
                .maximumResponseTokens(360)
            }
        }
    }

    @DynamicInstructionsBuilder
    private func lifecycleGroup<Content: DynamicInstructions>(
        stage: DynamicProfileWorkflowStage,
        runtime: DynamicProfileReviewRuntime,
        @DynamicInstructionsBuilder content: () -> Content
    ) -> some DynamicInstructions {
        #if canImport(FoundationModels, _version: 2.2)
        if #available(iOS 27.2, macOS 27.2, visionOS 27.2, *) {
            DynamicInstructionsGroup(content: content)
                .onActivate { @MainActor [state] in
                    state.recordInstructionEvent(.activated, stage: stage, runtime: runtime)
                }
                .onDeactivate { @MainActor [state] in
                    state.recordInstructionEvent(.deactivated, stage: stage, runtime: runtime)
                }
        } else {
            content()
        }
        #else
        content()
        #endif
    }

    private var reviewInstructions: Instructions {
        Instructions(
            """
            Review release evidence already present in this session's history. Do not invent checks, rerun tools, or treat the \
            bundled sample as a real release. Separate evidence that supports readiness from checks that remain unknown. If no tool \
            output appears earlier in the session, ask the person to run Inspect first.
            """
        )
    }
}
