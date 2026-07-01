import Foundation
import FoundationModelsKit

public struct AnalyzeNutritionUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "languages.analyze-nutrition",
        displayName: "Analyze Nutrition",
        summary: "Parses a meal description and generates brief nutrition insights."
    )

    private let analyzer: any NutritionAnalyzing

    public init(
        analyzer: any NutritionAnalyzing = FoundationModelsNutritionAnalyzer()
    ) {
        self.analyzer = analyzer
    }

    public func execute(
        _ request: AnalyzeNutritionRequest
    ) async throws -> AnalyzeNutritionResult {
        let trimmedFoodDescription = request.foodDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedResponseLanguage = request.responseLanguage.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFoodDescription.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing food description")
        }

        guard !trimmedResponseLanguage.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing response language")
        }

        return try await analyzer.analyzeNutrition(
            for: AnalyzeNutritionRequest(
                foodDescription: trimmedFoodDescription,
                responseLanguage: trimmedResponseLanguage,
                guardrails: request.guardrails,
                context: request.context
            )
        )
    }
}
