import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsContactsSearcher: ContactsSearching {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func searchContacts(for request: SearchContactsRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await toolInvoker.respond(
            to: "Find contacts named \(query)",
            using: ContactsTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
