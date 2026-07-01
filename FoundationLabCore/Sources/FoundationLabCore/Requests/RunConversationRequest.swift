import Foundation
import FoundationModelsKit
public struct RunConversationRequest: FoundationModelCapabilityRequest, Sendable {
    public let prompts: [String]
    public let systemPrompt: String?
    public let modelUseCase: FoundationModelUseCase
    public let guardrails: FoundationModelGuardrails?
    public let adapterURL: URL?
    public let generationOptions: FoundationModelGenerationOptions?
    public let context: FoundationModelInvocationContext

    public init(
        prompts: [String],
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        adapterURL: URL? = nil,
        generationOptions: FoundationModelGenerationOptions? = nil,
        context: FoundationModelInvocationContext
    ) {
        self.prompts = prompts
        self.systemPrompt = systemPrompt
        self.modelUseCase = modelUseCase
        self.guardrails = guardrails
        self.adapterURL = adapterURL
        self.generationOptions = generationOptions
        self.context = context
    }
}
