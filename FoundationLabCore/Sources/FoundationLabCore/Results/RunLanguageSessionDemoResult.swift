import Foundation
import FoundationModelsKit

public struct LanguageSessionExchange: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let label: String
    public let prompt: String
    public let response: String
    public let isError: Bool

    public init(
        id: UUID = UUID(),
        label: String,
        prompt: String,
        response: String,
        isError: Bool
    ) {
        self.id = id
        self.label = label
        self.prompt = prompt
        self.response = response
        self.isError = isError
    }
}

public struct RunLanguageSessionDemoResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let exchanges: [LanguageSessionExchange]
    public let metadata: FoundationModelExecutionMetadata

    public init(
        exchanges: [LanguageSessionExchange],
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.exchanges = exchanges
        self.metadata = metadata
    }
}
