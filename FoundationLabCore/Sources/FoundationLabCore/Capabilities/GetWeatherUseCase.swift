import Foundation
import FoundationModelsKit

public struct GetWeatherUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.get-weather",
        displayName: "Get Weather",
        summary: "Gets weather information using Foundation Models tool orchestration."
    )

    private let responder: any WeatherResponding

    public init(responder: any WeatherResponding = FoundationModelsWeatherResponder()) {
        self.responder = responder
    }

    public func execute(_ request: GetWeatherRequest) async throws -> FoundationModelTextGenerationResult {
        let location = request.location.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !location.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing location")
        }

        return try await responder.weather(for: request)
    }
}
