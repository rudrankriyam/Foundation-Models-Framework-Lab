import Foundation
import FoundationModelsKit

public protocol MusicCatalogSearching: Sendable {
    func searchMusic(for request: SearchMusicCatalogRequest) async throws -> FoundationModelTextGenerationResult
}
