import Foundation
import FoundationModelsKit
public struct SearchWebRequest: FoundationModelCapabilityRequest, Sendable {
    public let query: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let context: FoundationModelInvocationContext

    public init(
        query: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.query = query
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
