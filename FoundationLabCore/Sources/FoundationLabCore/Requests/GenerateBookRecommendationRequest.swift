import Foundation
import FoundationModelsKit

public struct GenerateBookRecommendationRequest: FoundationModelCapabilityRequest, Sendable, Hashable, Codable {
    public let prompt: String
    public let systemPrompt: String?
    public let context: FoundationModelInvocationContext

    public init(
        prompt: String,
        systemPrompt: String? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.prompt = prompt
        self.systemPrompt = systemPrompt
        self.context = context
    }
}
