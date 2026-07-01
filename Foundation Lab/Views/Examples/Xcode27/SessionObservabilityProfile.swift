//
//  SessionObservabilityProfile.swift
//  FoundationLab
//

#if compiler(>=6.4)
import FoundationLabCore
import FoundationModelsKit
import FoundationModels

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension SessionPropertyValues {
    @SessionPropertyEntry
    var sessionObservabilityToolCallCount = 0
}

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SessionObservabilityProfile: LanguageModelSession.DynamicProfile {
    private let tool = FoundationLabSessionObservabilityTool()
    let reasoningLevel: ContextOptions.ReasoningLevel?

    @SessionProperty(\.sessionObservabilityToolCallCount)
    private var toolCallCount

    var body: some LanguageModelSession.DynamicProfile {
        LanguageModelSession.Profile {
            Instructions("""
            Demonstrate an observable, read-only tool turn. Use the registered in-memory fact tool before answering, then ground the \
            answer only in its output. Never claim that another tool ran.
            """)
            tool
        }
        .reasoningLevel(reasoningLevel)
        .toolCallingMode(toolCallCount == 0 ? .required : .allowed)
        .maximumResponseTokens(300)
        .onToolCall {
            toolCallCount += 1
        }
    }
}
#endif
