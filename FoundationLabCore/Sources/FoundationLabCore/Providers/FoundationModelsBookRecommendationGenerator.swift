import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsBookRecommendationGenerator: BookRecommendationGenerating {
    public init() {}

    public func generateBookRecommendation(
        for request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult {
        let session: LanguageModelSession
        if let systemPrompt = request.systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(instructions: Instructions(systemPrompt))
        } else {
            session = LanguageModelSession()
        }

        let response = try await session.respond(
            to: Prompt(request.prompt),
            generating: BookRecommendation.self
        )

        let tokenCount = await session.transcript.tokenCount()

        return GenerateBookRecommendationResult(
            recommendation: response.content,
            metadata: FoundationModelExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
