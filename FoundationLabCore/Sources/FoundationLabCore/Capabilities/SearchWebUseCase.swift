import Foundation
import FoundationModelsKit

public struct SearchWebUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.search-web",
        displayName: "Search Web",
        summary: "Searches the web using a shared Foundation Models capability."
    )

    private let searcher: any WebSearching

    public init(searcher: any WebSearching = FoundationModelsWebSearcher()) {
        self.searcher = searcher
    }

    public func execute(_ request: SearchWebRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await searcher.searchWeb(for: request)
    }
}
