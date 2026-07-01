import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsWebPageSummarizer: WebPageSummarizing {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func summarizePage(for request: GenerateWebPageSummaryRequest) async throws -> FoundationModelTextGenerationResult {
        let url = request.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing URL")
        }

        return try await toolInvoker.respond(
            to: "Generate a social media summary for \(url)",
            using: WebMetadataTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
