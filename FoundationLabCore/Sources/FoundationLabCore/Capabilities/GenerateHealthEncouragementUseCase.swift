import Foundation
import FoundationModelsKit

public struct GenerateHealthEncouragementUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "health.generate-encouragement",
        displayName: "Generate Health Encouragement",
        summary: "Generates a short health encouragement message from health dashboard metrics."
    )

    private let generator: any HealthEncouragementGenerating

    public init(
        generator: any HealthEncouragementGenerating = FoundationModelsHealthEncouragementGenerator()
    ) {
        self.generator = generator
    }

    public func execute(
        _ request: GenerateHealthEncouragementRequest
    ) async throws -> GenerateHealthEncouragementResult {
        let trimmedTimeOfDay = request.timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTimeOfDay.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing time of day")
        }

        return try await generator.generateHealthEncouragement(
            for: GenerateHealthEncouragementRequest(
                healthScore: request.healthScore,
                stepsProgressPercentage: request.stepsProgressPercentage,
                sleepHours: request.sleepHours,
                activeEnergy: request.activeEnergy,
                timeOfDay: trimmedTimeOfDay,
                context: request.context
            )
        )
    }
}
