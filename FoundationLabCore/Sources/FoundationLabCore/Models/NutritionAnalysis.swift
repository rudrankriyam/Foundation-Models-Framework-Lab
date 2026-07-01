import Foundation
import FoundationModelsKit

public struct NutritionAnalysis: Sendable, Hashable, Codable {
    public let foodName: String
    public let calories: Int
    public let proteinGrams: Int
    public let carbsGrams: Int
    public let fatGrams: Int
    public let insights: String

    public init(
        foodName: String,
        calories: Int,
        proteinGrams: Int,
        carbsGrams: Int,
        fatGrams: Int,
        insights: String
    ) {
        self.foodName = foodName
        self.calories = calories
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatGrams = fatGrams
        self.insights = insights
    }
}
