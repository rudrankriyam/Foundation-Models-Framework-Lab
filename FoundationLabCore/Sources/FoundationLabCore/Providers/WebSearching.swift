import Foundation
import FoundationModelsKit

public protocol WebSearching: Sendable {
    func searchWeb(for request: SearchWebRequest) async throws -> FoundationModelTextGenerationResult
}
