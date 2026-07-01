import Foundation
import FoundationModelsKit

public protocol LocationResponding: Sendable {
    func getCurrentLocation(for request: GetCurrentLocationRequest) async throws -> FoundationModelTextGenerationResult
}
