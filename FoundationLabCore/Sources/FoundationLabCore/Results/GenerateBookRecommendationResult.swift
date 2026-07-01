import Foundation
import FoundationModelsKit

public struct GenerateBookRecommendationResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let recommendation: BookRecommendation
    public let metadata: FoundationModelExecutionMetadata

    public init(
        recommendation: BookRecommendation,
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.recommendation = recommendation
        self.metadata = metadata
    }
}
