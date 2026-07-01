import Foundation
import FoundationModelsKit

public struct SearchMusicCatalogUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.search-music-catalog",
        displayName: "Search Music Catalog",
        summary: "Searches the Apple Music catalog using shared Foundation Models orchestration."
    )

    private let searcher: any MusicCatalogSearching

    public init(searcher: any MusicCatalogSearching = FoundationModelsMusicCatalogSearcher()) {
        self.searcher = searcher
    }

    public func execute(_ request: SearchMusicCatalogRequest) async throws -> FoundationModelTextGenerationResult {
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing query")
        }

        return try await searcher.searchMusic(for: request)
    }
}
