import Foundation
import FoundationModelsKit
@testable import FoundationLabCore
import Testing

struct GenerateHealthEncouragementUseCaseTests {
    @Test
    func useCaseDelegatesToGenerator() async throws {
        let request = GenerateHealthEncouragementRequest(
            healthScore: 82,
            stepsProgressPercentage: 91,
            sleepHours: 7.5,
            activeEnergy: 540,
            timeOfDay: "morning",
            context: FoundationModelInvocationContext(source: .app)
        )
        let expected = GenerateHealthEncouragementResult(message: "You are building great momentum today.")
        let generator = StubHealthEncouragementGenerator(result: expected)

        let result = try await GenerateHealthEncouragementUseCase(generator: generator).execute(request)

        #expect(result == expected)
        #expect(generator.lastRequest == request)
    }

    @Test
    func useCaseRejectsBlankTimeOfDay() async throws {
        let request = GenerateHealthEncouragementRequest(
            healthScore: 82,
            stepsProgressPercentage: 91,
            sleepHours: 7.5,
            activeEnergy: 540,
            timeOfDay: "   ",
            context: FoundationModelInvocationContext(source: .app)
        )

        await #expect(throws: FoundationLabCoreError.self) {
            _ = try await GenerateHealthEncouragementUseCase(
                generator: StubHealthEncouragementGenerator(
                    result: GenerateHealthEncouragementResult(message: "unused")
                )
            ).execute(request)
        }
    }
}

private final class StubHealthEncouragementGenerator: HealthEncouragementGenerating, @unchecked Sendable {
    let result: GenerateHealthEncouragementResult
    private(set) var lastRequest: GenerateHealthEncouragementRequest?

    init(result: GenerateHealthEncouragementResult) {
        self.result = result
    }

    func generateHealthEncouragement(
        for request: GenerateHealthEncouragementRequest
    ) async throws -> GenerateHealthEncouragementResult {
        lastRequest = request
        return result
    }
}
