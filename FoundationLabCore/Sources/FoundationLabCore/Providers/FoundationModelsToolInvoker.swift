import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsToolInvoker: Sendable {
    public init() {}

    public func respond<ToolType: Tool>(
        to prompt: String,
        using tool: ToolType,
        systemPrompt: String? = nil,
        modelUseCase: FoundationModelUseCase = .general,
        guardrails: FoundationModelGuardrails? = nil,
        generationOptions: FoundationModelGenerationOptions? = nil
    ) async throws -> FoundationModelTextGenerationResult {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing prompt")
        }

        let model = SystemLanguageModel(
            useCase: modelUseCase.foundationModelsValue,
            guardrails: (guardrails ?? FoundationModelGuardrails.default).foundationModelsValue
        )
        let session: LanguageModelSession

        if let systemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines),
           !systemPrompt.isEmpty {
            session = LanguageModelSession(
                model: model,
                tools: [tool],
                instructions: Instructions(systemPrompt)
            )
        } else {
            session = LanguageModelSession(model: model, tools: [tool])
        }

        let responseContent: String
        if let generationOptions {
            responseContent = try await session.respond(
                to: Prompt(trimmedPrompt),
                options: generationOptions.foundationModelsValue
            ).content
        } else {
            responseContent = try await session.respond(to: Prompt(trimmedPrompt)).content
        }

        let tokenCount = await session.transcript.tokenCount(using: model)

        return FoundationModelTextGenerationResult(
            content: responseContent,
            metadata: FoundationModelExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
