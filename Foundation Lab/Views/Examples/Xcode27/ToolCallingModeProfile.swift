//
//  ToolCallingModeProfile.swift
//  FoundationLab
//

#if compiler(>=6.4)
import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SessionPropertyValues {
    @SessionPropertyEntry
    var toolCallingLabCallCount = 0
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ToolCallingModeProfile: LanguageModelSession.DynamicProfile {
    let tool: LocalReleaseRecordTool
    let mode: ToolCallingExperimentMode

    @SessionProperty(\.toolCallingLabCallCount)
    private var callCount

    var body: some LanguageModelSession.DynamicProfile {
        LanguageModelSession.Profile {
            Instructions(
                """
                The read-only local tool is the only source for the app's fixture release record. Use it when policy permits. If \
                tool calling is unavailable, say that you cannot inspect the local record instead of inventing its contents.
                """
            )
            tool
        }
        .toolCallingMode(effectiveMode)
        .onToolCall {
            callCount += 1
        }
    }

    private var effectiveMode: GenerationOptions.ToolCallingMode {
        if mode == .required, callCount > 0 {
            .allowed
        } else {
            mode.frameworkValue
        }
    }
}
#endif
