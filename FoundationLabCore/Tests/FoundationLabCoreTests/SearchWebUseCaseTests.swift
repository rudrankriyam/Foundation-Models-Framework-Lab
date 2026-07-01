import XCTest
import FoundationModelsKit
@testable import FoundationLabCore

final class SearchWebUseCaseTests: XCTestCase {
    func testUseCaseRejectsBlankQuery() async {
        let useCase = SearchWebUseCase(searcher: WebSearcherStub())

        await XCTAssertThrowsErrorAsync(
            try await useCase.execute(
                SearchWebRequest(
                    query: "   ",
                    context: FoundationModelInvocationContext(source: .app)
                )
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest("Missing query")
            )
        }
    }

    func testUseCaseDelegatesToSearcher() async throws {
        let expected = FoundationModelTextGenerationResult(
            content: "Top result summary.",
            metadata: FoundationModelExecutionMetadata(
                provider: "Stub",
                modelIdentifier: "web-stub",
                tokenCount: 31
            )
        )
        let stub = WebSearcherStub(result: expected)
        let useCase = SearchWebUseCase(searcher: stub)

        let result = try await useCase.execute(
            SearchWebRequest(
                query: " Foundation Models Framework ",
                context: FoundationModelInvocationContext(
                    source: .cli,
                    localeIdentifier: "en_US"
                )
            )
        )

        XCTAssertEqual(result, expected)
        XCTAssertEqual(stub.lastRequest?.query, " Foundation Models Framework ")
        XCTAssertEqual(stub.lastRequest?.context.source, .cli)
    }
}

private final class WebSearcherStub: WebSearching, @unchecked Sendable {
    private(set) var lastRequest: SearchWebRequest?
    private let result: FoundationModelTextGenerationResult

    init(
        result: FoundationModelTextGenerationResult = FoundationModelTextGenerationResult(
            content: "Default search result"
        )
    ) {
        self.result = result
    }

    func searchWeb(for request: SearchWebRequest) async throws -> FoundationModelTextGenerationResult {
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
