import Foundation
import FoundationModelsKit

public struct RunLanguageSessionDemoRequest: FoundationModelCapabilityRequest {
    public let steps: [LanguageConversationStep]
    public let systemPrompt: String?
    public let context: FoundationModelInvocationContext

    public init(
        steps: [LanguageConversationStep] = FoundationLabLanguageCatalog.defaultConversationSteps,
        systemPrompt: String? = FoundationLabLanguageCatalog.multilingualSystemPrompt,
        context: FoundationModelInvocationContext
    ) {
        self.steps = steps
        self.systemPrompt = systemPrompt
        self.context = context
    }
}
