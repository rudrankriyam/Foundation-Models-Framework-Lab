import Foundation
import FoundationModelsKit

public struct FoundationModelsWebSearcher: WebSearching {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func searchWeb(for request: SearchWebRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await toolInvoker.respond(
            to: query,
            using: Search1WebSearchTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
