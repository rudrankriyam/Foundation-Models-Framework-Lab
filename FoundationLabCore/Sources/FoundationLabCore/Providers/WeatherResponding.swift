import Foundation
import FoundationModelsKit

public protocol WeatherResponding: Sendable {
    func weather(for request: GetWeatherRequest) async throws -> FoundationModelTextGenerationResult
}
