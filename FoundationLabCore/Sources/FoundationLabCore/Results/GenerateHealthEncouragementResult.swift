import Foundation
import FoundationModelsKit

public struct GenerateHealthEncouragementResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let message: String
    public let metadata: FoundationModelExecutionMetadata

    public init(
        message: String,
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.message = message
        self.metadata = metadata
    }
}
