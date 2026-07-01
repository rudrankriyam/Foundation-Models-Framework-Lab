import Foundation
import FoundationModels
import XCTest
import FoundationModelsKit
@testable import FoundationLabCore

final class FoundationModelErrorProjectionTests: XCTestCase {
    func testGenerationErrorContextOverflowDoesNotInventUnavailableDetails() throws {
        let error = LanguageModelSession.GenerationError.exceededContextWindowSize(
            .init(debugDescription: "Legacy context overflow")
        )
        let projection = try XCTUnwrap(FoundationModelErrorProjection.project(error))

        XCTAssertEqual(projection.category, .contextSizeExceeded)
        XCTAssertNil(projection.contextSize)
        XCTAssertNil(projection.attemptedTokenCount)
        XCTAssertNil(projection.resetDate)
        XCTAssertNil(projection.capability)
        XCTAssertTrue(projection.isContextOverflow)
        XCTAssertTrue(FoundationModelErrorProjection.isContextOverflow(error))

        let encoded = try JSONEncoder().encode(projection)
        let decoded = try JSONDecoder().decode(
            FoundationModelErrorProjection.self,
            from: encoded
        )
        XCTAssertEqual(decoded, projection)
        let payload = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertFalse(payload.contains("Legacy context overflow"))
    }

    func testGenerationErrorCategoriesRemainDistinctFromOverflow() throws {
        let fixtures: [(
            LanguageModelSession.GenerationError,
            FoundationModelErrorProjection.Category
        )] = [
            (.assetsUnavailable(.init(debugDescription: "Assets")), .assetsUnavailable),
            (.guardrailViolation(.init(debugDescription: "Guardrail")), .guardrailViolation),
            (.unsupportedGuide(.init(debugDescription: "Guide")), .unsupportedGenerationGuide),
            (
                .unsupportedLanguageOrLocale(.init(debugDescription: "Language")),
                .unsupportedLanguageOrLocale
            ),
            (.decodingFailure(.init(debugDescription: "Decoding")), .decodingFailure),
            (.rateLimited(.init(debugDescription: "Rate")), .rateLimited),
            (.concurrentRequests(.init(debugDescription: "Concurrent")), .concurrentRequests),
            (
                .refusal(
                    .init(transcriptEntries: []),
                    .init(debugDescription: "Refusal")
                ),
                .refusal
            )
        ]

        for (error, expectedCategory) in fixtures {
            let projection = try XCTUnwrap(FoundationModelErrorProjection.project(error))
            XCTAssertEqual(projection.category, expectedCategory)
            XCTAssertFalse(FoundationModelErrorProjection.isContextOverflow(error))
        }
    }

    func testUnrelatedErrorsAreNotProjectedAsOverflow() {
        struct UnrelatedError: Error {}
        let error = UnrelatedError()

        XCTAssertNil(FoundationModelErrorProjection.project(error))
        XCTAssertFalse(FoundationModelErrorProjection.isContextOverflow(error))
    }
}
