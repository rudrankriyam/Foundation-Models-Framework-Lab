//
//  DynamicProfileWorkflowProfile.swift
//  FoundationLab
//

#if compiler(>=6.4)
import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileWorkflowProfile: LanguageModelSession.DynamicProfile {
    let state: DynamicProfileWorkflowState
    let tool: LocalReleaseRecordTool
    let privateCloudComputeModel: PrivateCloudComputeLanguageModel

    var body: some LanguageModelSession.DynamicProfile {
        switch state.stage {
        case .inspect:
            LanguageModelSession.Profile {
                Instructions(
                    """
                    Inspect the bundled sample release record. Call the read-only tool before answering, use only its output as \
                    release evidence, and label anything else as unknown. Never imply that the tool reads GitHub or a real build.
                    """
                )
                tool
            }
            .model(SystemLanguageModel.default)
            .temperature(0.1)
            .maximumResponseTokens(320)
            .toolCallingMode(state.requiresInspectionToolCall ? .required : .allowed)
            .onToolCall {
                state.requiresInspectionToolCall = false
            }

        case .review:
            if state.reviewRuntime == .privateCloudCompute {
                LanguageModelSession.Profile {
                    reviewInstructions
                }
                .model(privateCloudComputeModel)
                .reasoningLevel(.moderate)
                .temperature(0.1)
                .maximumResponseTokens(480)
            } else {
                LanguageModelSession.Profile {
                    reviewInstructions
                }
                .model(SystemLanguageModel.default)
                .temperature(0.1)
                .maximumResponseTokens(360)
            }
        }
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
#endif
