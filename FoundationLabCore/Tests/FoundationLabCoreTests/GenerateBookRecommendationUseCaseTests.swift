import XCTest
import FoundationModelsKit
@testable import FoundationLabCore

final class GenerateBookRecommendationUseCaseTests: XCTestCase {
    func testUseCaseRejectsBlankPrompt() async {
        let useCase = GenerateBookRecommendationUseCase(
            generator: BookRecommendationGeneratorStub()
        )

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                GenerateBookRecommendationRequest(
                    prompt: "   ",
                    context: FoundationModelInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing prompt")
            )
        }
    }

    func testUseCaseDelegatesToGenerator() async throws {
        let expected = GenerateBookRecommendationResult(
            recommendation: BookRecommendation(
                title: "The Left Hand of Darkness",
                author: "Ursula K. Le Guin",
                description: "A diplomat navigates an icy world while confronting politics and identity.",
                genre: .sciFi
            ),
            metadata: FoundationModelExecutionMetadata(
                provider: "Stub",
                modelIdentifier: "stub-model",
                tokenCount: 42
            )
        )
        let stub = BookRecommendationGeneratorStub(result: expected)
        let useCase = GenerateBookRecommendationUseCase(generator: stub)

        let result = try await useCase.execute(
            GenerateBookRecommendationRequest(
                prompt: "Suggest a thoughtful science fiction novel",
                systemPrompt: "Be concise",
                context: FoundationModelInvocationContext(
                    source: .app,
                    localeIdentifier: "en_US"
                )
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.prompt, "Suggest a thoughtful science fiction novel")
        XCTAssertEqual(stub.lastRequest?.systemPrompt, "Be concise")
        XCTAssertEqual(stub.lastRequest?.context.localeIdentifier, "en_US")
    }
}

private final class BookRecommendationGeneratorStub: BookRecommendationGenerating, @unchecked Sendable {
    private(set) var lastRequest: GenerateBookRecommendationRequest?
    private let result: GenerateBookRecommendationResult

    init(
        result: GenerateBookRecommendationResult = GenerateBookRecommendationResult(
            recommendation: BookRecommendation(
                title: "Default Title",
                author: "Default Author",
                description: "Default description.",
                genre: .fiction
            )
        )
    ) {
        self.result = result
    }

    func generateBookRecommendation(
        for request: GenerateBookRecommendationRequest
    ) async throws -> GenerateBookRecommendationResult {
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
