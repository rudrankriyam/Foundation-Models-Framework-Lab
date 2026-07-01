import Foundation
import FoundationModelsKit

public struct AnalyzeNutritionRequest: FoundationModelCapabilityRequest, Sendable, Hashable, Codable {
    public let foodDescription: String
    public let responseLanguage: String
    public let guardrails: FoundationModelGuardrails?
    public let context: FoundationModelInvocationContext

    public init(
        foodDescription: String,
        responseLanguage: String,
        guardrails: FoundationModelGuardrails? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.foodDescription = foodDescription
        self.responseLanguage = responseLanguage
        self.guardrails = guardrails
        self.context = context
    }
}
