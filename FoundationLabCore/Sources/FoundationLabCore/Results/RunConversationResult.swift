import Foundation
import FoundationModelsKit

public struct ConversationExchange: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let prompt: String
    public let response: String
    public let isError: Bool

    public init(
        id: UUID = UUID(),
        prompt: String,
        response: String,
        isError: Bool
    ) {
        self.id = id
        self.prompt = prompt
        self.response = response
        self.isError = isError
    }
}

public struct RunConversationResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let exchanges: [ConversationExchange]
    public let metadata: FoundationModelExecutionMetadata

    public init(
        exchanges: [ConversationExchange],
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.exchanges = exchanges
        self.metadata = metadata
    }
}
