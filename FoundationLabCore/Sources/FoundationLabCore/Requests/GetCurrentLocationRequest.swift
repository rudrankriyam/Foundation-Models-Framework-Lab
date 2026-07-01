import Foundation
import FoundationModelsKit
public struct GetCurrentLocationRequest: FoundationModelCapabilityRequest, Sendable {
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let context: FoundationModelInvocationContext

    public init(
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
