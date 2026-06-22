import FoundationModels
import FoundationModelsKit

struct FoundationLabConversationTokenSnapshot {
    let legacyTokenCount: Int
    let usage: ModelTokenUsage
}

enum FoundationLabConversationTokenUsageSource {
    case context
    case accumulatedSession
}

func foundationLabConversationTokenSnapshot(
    session: LanguageModelSession,
    model: SystemLanguageModel,
    runtime: FoundationLabModelRuntime,
    usageSource: FoundationLabConversationTokenUsageSource = .accumulatedSession
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

    let observedSessionUsage: ModelTokenUsage?
    switch usageSource {
    case .context:
        observedSessionUsage = nil
    case .accumulatedSession:
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            observedSessionUsage = ModelTokenUsage(observing: session.usage, scope: .session)
        } else {
            observedSessionUsage = nil
        }
        #else
        observedSessionUsage = nil
        #endif
    }

    return foundationLabConversationTokenSnapshot(
        contextUsage: contextUsage,
        observedSessionUsage: observedSessionUsage,
        usageSource: usageSource
    )
}

func foundationLabConversationTokenSnapshot(
    contextUsage: ModelTokenUsage,
    observedSessionUsage: ModelTokenUsage?,
    usageSource: FoundationLabConversationTokenUsageSource
) -> FoundationLabConversationTokenSnapshot {
    let resolvedUsage = switch usageSource {
    case .context:
        contextUsage
    case .accumulatedSession:
        observedSessionUsage ?? contextUsage
    }

    return FoundationLabConversationTokenSnapshot(
        legacyTokenCount: contextUsage.totalTokenCount,
        usage: resolvedUsage
    )
}
