import FoundationModelsKit
import Testing
@testable import FoundationLabCore

@Test("A recreated session publishes context usage until generation completes")
func recreatedSessionPublishesContextUsage() {
    let contextUsage = ModelTokenUsage(
        inputTokenCount: 42,
        measurement: .tokenized,
        scope: .context
    )
    let emptyObservedUsage = ModelTokenUsage(
        input: .init(totalTokenCount: 0),
        output: .init(totalTokenCount: 0),
        measurement: .observed,
        scope: .session
    )

    let snapshot = foundationLabConversationTokenSnapshot(
        contextUsage: contextUsage,
        observedSessionUsage: emptyObservedUsage,
        usageSource: .context
    )

    #expect(snapshot.legacyTokenCount == 42)
    #expect(snapshot.usage == contextUsage)
    #expect(snapshot.usage.measurement == .tokenized)
    #expect(snapshot.usage.scope == .context)
}
