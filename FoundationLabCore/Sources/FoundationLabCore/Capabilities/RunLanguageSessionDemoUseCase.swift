import Foundation
import FoundationModelsKit

public struct RunLanguageSessionDemoUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.run-language-session-demo",
        displayName: "Run Language Session Demo",
        summary: "Runs the shared multilingual conversation demo through the FoundationLabCore conversation engine."
    )

    private let conversationRunner: RunConversationUseCase

    public init(conversationRunner: RunConversationUseCase = RunConversationUseCase()) {
        self.conversationRunner = conversationRunner
    }

    public func execute(
        _ request: RunLanguageSessionDemoRequest
    ) async throws -> RunLanguageSessionDemoResult {
        guard !request.steps.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing conversation steps")
        }

        let result = try await conversationRunner.execute(
            RunConversationRequest(
                prompts: request.steps.map(\.prompt),
                systemPrompt: request.systemPrompt,
                context: request.context
            )
        )

        let exchanges = zip(request.steps, result.exchanges).map { step, exchange in
            LanguageSessionExchange(
                label: step.label,
                prompt: exchange.prompt,
                response: exchange.response,
                isError: exchange.isError
            )
        }

        return RunLanguageSessionDemoResult(
            exchanges: exchanges,
            metadata: result.metadata
        )
    }
}
