import Foundation
import FoundationModelsKit

public struct GenerateMultilingualResponsesRequest: FoundationModelCapabilityRequest {
    public let supportedLanguages: [FoundationModelSupportedLanguage]?
    public let maximumResults: Int?
    public let context: FoundationModelInvocationContext

    public init(
        supportedLanguages: [FoundationModelSupportedLanguage]? = nil,
        maximumResults: Int? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.supportedLanguages = supportedLanguages
        self.maximumResults = maximumResults
        self.context = context
    }
}
