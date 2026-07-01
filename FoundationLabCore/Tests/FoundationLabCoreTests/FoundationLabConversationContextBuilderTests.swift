import FoundationLabCore
import Testing
import FoundationModelsKit

struct FoundationLabConversationContextBuilderTests {
    @Test
    func contextInstructionsIncludeSummaryDetails() {
        let summary = FoundationModelConversationSummary(
            summary: "We talked about weekend travel plans.",
            keyTopics: ["Travel", "Budget"],
            userPreferences: ["Prefers trains", "Wants scenic routes"]
        )

        let instructions = FoundationModelConversationContextBuilder.contextInstructions(
            baseInstructions: "You are a helpful planner.",
            summary: summary,
            continuationNote: "Keep recommendations concise."
        )

        #expect(instructions.contains("You are a helpful planner."))
        #expect(instructions.contains("We talked about weekend travel plans."))
        #expect(instructions.contains("Travel"))
        #expect(instructions.contains("Prefers trains"))
        #expect(instructions.contains("Keep recommendations concise."))
    }

    @Test
    @MainActor
    func conversationEngineTracksConfiguredContextWindow() {
        let engine = FoundationModelConversationEngine(
            configuration: FoundationModelConversationConfiguration(
                baseInstructions: "You are a helpful assistant.",
                summaryInstructions: "Summarize clearly.",
                summaryPromptPreamble: "Summarize this conversation:",
                conversationUserLabel: "User:",
                conversationAssistantLabel: "Assistant:",
                continuationNote: "Continue naturally."
            )
        )

        #expect(engine.sessionCount == 1)
        #expect(engine.currentTokenCount == 0)

        engine.setMaxContextSize(8_192)

        #expect(engine.maxContextSize == 8_192)
    }
}
