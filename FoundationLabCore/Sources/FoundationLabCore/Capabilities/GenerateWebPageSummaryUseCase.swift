import Foundation
import FoundationModelsKit

public struct GenerateWebPageSummaryUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.generate-web-page-summary",
        displayName: "Generate Web Page Summary",
        summary: "Summarizes a web page using shared Foundation Models orchestration."
    )

    private let summarizer: any WebPageSummarizing

    public init(summarizer: any WebPageSummarizing = FoundationModelsWebPageSummarizer()) {
        self.summarizer = summarizer
    }

    public func execute(_ request: GenerateWebPageSummaryRequest) async throws -> FoundationModelTextGenerationResult {
        let trimmedURL = request.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURL.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing URL")
        }

        guard let parsedURL = URL(string: trimmedURL),
              let scheme = parsedURL.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              parsedURL.host != nil else {
            throw FoundationLabCoreError.invalidRequest("URL must use http or https")
        }

        return try await summarizer.summarizePage(for: request)
    }
}
