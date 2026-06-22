import FoundationModels
import FoundationModelsKit

struct FoundationLabConversationTokenSnapshot {
    let legacyTokenCount: Int
    let usage: ModelTokenUsage
}

func foundationLabConversationTokenSnapshot(
    session: LanguageModelSession,
    model: SystemLanguageModel,
    runtime: FoundationLabModelRuntime
) async -> FoundationLabConversationTokenSnapshot {
    let contextUsage: ModelTokenUsage
    switch runtime {
    case .onDevice:
        contextUsage = await session.transcript.tokenUsage(using: model)
    case .privateCloudCompute:
        contextUsage = ModelTokenUsage(
            inputTokenCount: session.transcript.estimatedTokenCount,
            measurement: .estimated
        )
    }

    #if compiler(>=6.4)
    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
        return FoundationLabConversationTokenSnapshot(
            legacyTokenCount: contextUsage.totalTokenCount,
            usage: ModelTokenUsage(observing: session.usage, scope: .session)
        )
    }
    #endif

    return FoundationLabConversationTokenSnapshot(
        legacyTokenCount: contextUsage.totalTokenCount,
        usage: contextUsage
    )
}
