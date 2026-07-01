import Foundation
import FoundationModelsKit
public struct GenerateWebPageSummaryRequest: FoundationModelCapabilityRequest, Sendable {
    public let url: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let context: FoundationModelInvocationContext

    public init(
        url: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.url = url
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
