import Foundation
import FoundationModelsKit

public struct AnalyzeNutritionResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let analysis: NutritionAnalysis
    public let metadata: FoundationModelExecutionMetadata

    public init(
        analysis: NutritionAnalysis,
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.analysis = analysis
        self.metadata = metadata
    }
}
