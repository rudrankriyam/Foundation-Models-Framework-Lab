import Foundation
import FoundationModelsKit
public struct GetWeatherRequest: FoundationModelCapabilityRequest, Sendable {
    public let location: String
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let context: FoundationModelInvocationContext

    public init(
        location: String,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.location = location
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.context = context
    }
}
