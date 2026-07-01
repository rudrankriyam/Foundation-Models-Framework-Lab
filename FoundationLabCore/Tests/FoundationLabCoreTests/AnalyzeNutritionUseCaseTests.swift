import XCTest
import FoundationModelsKit
@testable import FoundationLabCore

final class AnalyzeNutritionUseCaseTests: XCTestCase {
    func testUseCaseRejectsBlankFoodDescription() async {
        let useCase = AnalyzeNutritionUseCase(
            analyzer: NutritionAnalyzerStub()
        )

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                AnalyzeNutritionRequest(
                    foodDescription: "   ",
                    responseLanguage: "English (en-US)",
                    context: FoundationModelInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing food description")
            )
        }
    }

    func testUseCaseRejectsBlankResponseLanguage() async {
        let useCase = AnalyzeNutritionUseCase(
            analyzer: NutritionAnalyzerStub()
        )

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                AnalyzeNutritionRequest(
                    foodDescription: "2 eggs and toast",
                    responseLanguage: "   ",
                    context: FoundationModelInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing response language")
            )
        }
    }

    func testUseCaseDelegatesToAnalyzer() async throws {
        let expected = AnalyzeNutritionResult(
            analysis: NutritionAnalysis(
                foodName: "Chicken salad",
                calories: 420,
                proteinGrams: 32,
                carbsGrams: 18,
                fatGrams: 21,
                insights: "A protein-rich meal with balanced fats."
            ),
            metadata: FoundationModelExecutionMetadata(
                provider: "Stub",
                modelIdentifier: "nutrition-stub",
                tokenCount: 84
            )
        )
        let stub = NutritionAnalyzerStub(result: expected)
        let useCase = AnalyzeNutritionUseCase(analyzer: stub)

        let result = try await useCase.execute(
            AnalyzeNutritionRequest(
                foodDescription: " Chicken salad with avocado ",
                responseLanguage: "English (en-US)",
                context: FoundationModelInvocationContext(
                    source: .app,
                    localeIdentifier: "en_US"
                )
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.foodDescription, "Chicken salad with avocado")
        XCTAssertEqual(stub.lastRequest?.responseLanguage, "English (en-US)")
        XCTAssertEqual(stub.lastRequest?.context.localeIdentifier, "en_US")
    }
}

private final class NutritionAnalyzerStub: NutritionAnalyzing, @unchecked Sendable {
    private(set) var lastRequest: AnalyzeNutritionRequest?
    private let result: AnalyzeNutritionResult

    init(
        result: AnalyzeNutritionResult = AnalyzeNutritionResult(
            analysis: NutritionAnalysis(
                foodName: "Default Meal",
                calories: 300,
                proteinGrams: 20,
                carbsGrams: 25,
                fatGrams: 10,
                insights: "Default insight."
            )
        )
    ) {
        self.result = result
    }

    func analyzeNutrition(
        for request: AnalyzeNutritionRequest
    ) async throws -> AnalyzeNutritionResult {
        lastRequest = request
        return result
    }
}

private extension XCTestCase {
    func XCTAssertThrowsErrorAsync<T>(
        _ expression: @autoclosure () async throws -> T,
        _ errorHandler: (Error) -> Void
    ) async {
        do {
            _ = try await expression()
            XCTFail("Expected error to be thrown")
        } catch {
            errorHandler(error)
        }
    }
}
