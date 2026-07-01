import Foundation
import FoundationModelsKit

public struct MultilingualResponseEntry: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let language: String
    public let flag: String
    public let prompt: String
    public let response: String
    public let isError: Bool
    public let metadata: FoundationModelExecutionMetadata?

    public init(
        id: UUID = UUID(),
        language: String,
        flag: String,
        prompt: String,
        response: String,
        isError: Bool,
        metadata: FoundationModelExecutionMetadata? = nil
    ) {
        self.id = id
        self.language = language
        self.flag = flag
        self.prompt = prompt
        self.response = response
        self.isError = isError
        self.metadata = metadata
    }
}

public struct GenerateMultilingualResponsesResult: FoundationModelCapabilityResult, Sendable, Hashable, Codable {
    public let prompts: [LanguagePrompt]
    public let responses: [MultilingualResponseEntry]
    public let metadata: FoundationModelExecutionMetadata

    public init(
        prompts: [LanguagePrompt],
        responses: [MultilingualResponseEntry],
        metadata: FoundationModelExecutionMetadata = FoundationModelExecutionMetadata()
    ) {
        self.prompts = prompts
        self.responses = responses
        self.metadata = metadata
    }
}
