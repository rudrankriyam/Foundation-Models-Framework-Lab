import Foundation
import FoundationModelsKit

public protocol HealthDataQuerying: Sendable {
    func queryHealthData(for request: QueryHealthDataRequest) async throws -> FoundationModelTextGenerationResult
}
