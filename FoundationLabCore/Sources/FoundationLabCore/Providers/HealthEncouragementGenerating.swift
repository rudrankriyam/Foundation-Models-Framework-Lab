import Foundation
import FoundationModelsKit

public protocol HealthEncouragementGenerating: Sendable {
    func generateHealthEncouragement(
        for request: GenerateHealthEncouragementRequest
    ) async throws -> GenerateHealthEncouragementResult
}
