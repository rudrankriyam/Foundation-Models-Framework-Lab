import Foundation
import FoundationModelsKit

public struct GenerateHealthEncouragementRequest: FoundationModelCapabilityRequest, Sendable, Hashable, Codable {
    public let healthScore: Int
    public let stepsProgressPercentage: Int
    public let sleepHours: Double
    public let activeEnergy: Int
    public let timeOfDay: String
    public let context: FoundationModelInvocationContext

    public init(
        healthScore: Int,
        stepsProgressPercentage: Int,
        sleepHours: Double,
        activeEnergy: Int,
        timeOfDay: String,
        context: FoundationModelInvocationContext
    ) {
        self.healthScore = healthScore
        self.stepsProgressPercentage = stepsProgressPercentage
        self.sleepHours = sleepHours
        self.activeEnergy = activeEnergy
        self.timeOfDay = timeOfDay
        self.context = context
    }
}
