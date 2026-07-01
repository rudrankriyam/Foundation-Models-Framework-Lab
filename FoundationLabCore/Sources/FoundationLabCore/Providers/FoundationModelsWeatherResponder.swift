import Foundation
import FoundationModelsTools
import FoundationModelsKit

public struct FoundationModelsWeatherResponder: WeatherResponding {
    private let toolInvoker: FoundationModelsToolInvoker

    public init(toolInvoker: FoundationModelsToolInvoker = FoundationModelsToolInvoker()) {
        self.toolInvoker = toolInvoker
    }

    public func weather(for request: GetWeatherRequest) async throws -> FoundationModelTextGenerationResult {
        let location = request.location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !location.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing location")
        }

        return try await toolInvoker.respond(
            to: "What's the weather like in \(location)?",
            using: WeatherTool(),
            systemPrompt: request.systemPrompt,
            modelUseCase: request.modelUseCase,
            guardrails: request.guardrails
        )
    }
}
