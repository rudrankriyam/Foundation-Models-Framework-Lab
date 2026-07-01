import Foundation
import FoundationModelsKit

public protocol WebPageSummarizing: Sendable {
    func summarizePage(for request: GenerateWebPageSummaryRequest) async throws -> FoundationModelTextGenerationResult
}
