import Foundation
import FoundationModelsKit

public struct GenerateBookRecommendationUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "examples.generate-book-recommendation",
        displayName: "Generate Book Recommendation",
        summary: "Generates a structured book recommendation."
    )

    private let generator: any BookRecommendationGenerating

    public init(
        generator: any BookRecommendationGenerating = FoundationModelsBookRecommendationGenerator()
    ) {
        self.generator = generator
    }

    public func execute(
        _ request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult {
        let trimmedPrompt = request.prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        return try await generator.generateBookRecommendation(
            for: GenerateBookRecommendationRequest(
                prompt: trimmedPrompt,
                systemPrompt: request.systemPrompt,
                context: request.context
            )
        )
    }
}
