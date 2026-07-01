import Foundation
import FoundationModelsKit

public struct RunSchemaExampleResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let content: String
    public let metadata: FoundationModelExecutionMetadata

    public init(
        content: String,
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.content = content
        self.metadata = metadata
    }
}
