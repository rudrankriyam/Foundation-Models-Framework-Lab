import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsHealthEncouragementGenerator: HealthEncouragementGenerating {
    public init() {}

    public func generateHealthEncouragement(
        for request: GenerateHealthEncouragementRequest
    ) async throws -> GenerateHealthEncouragementResult {
        let trimmedTimeOfDay = request.timeOfDay.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTimeOfDay.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing time of day")
        }

        let session = LanguageModelSession(
            instructions: Instructions(
                """
                You are a supportive health coach.
                Generate a brief, encouraging message (max 15 words) based on the user's health data.
                Do NOT use quotes, numbers, specific metrics, or emojis.
                Focus on general encouragement and motivation.
                """
            )
        )

        let prompt = """
        Health Score: \(request.healthScore)/100
        Steps Progress: \(request.stepsProgressPercentage)% of daily goal
        Sleep: \(String(format: "%.1f", request.sleepHours)) hours last night
        Active Energy: \(request.activeEnergy) calories burned today
        Time of Day: \(trimmedTimeOfDay)

        Generate a personalized, encouraging message.
        """

        let response = try await session.respond(to: Prompt(prompt))
        let tokenCount = await session.transcript.tokenCount()

        return GenerateHealthEncouragementResult(
            message: response.content,
            metadata: FoundationModelExecutionMetadata(
                provider: "Foundation Models",
                tokenCount: tokenCount
            )
        )
    }
}
