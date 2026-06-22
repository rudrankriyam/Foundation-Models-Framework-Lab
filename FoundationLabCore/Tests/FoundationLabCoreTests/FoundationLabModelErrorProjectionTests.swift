import Foundation
import FoundationModels
import XCTest
@testable import FoundationLabCore

final class FoundationLabModelErrorProjectionTests: XCTestCase {
    func testGenerationErrorContextOverflowDoesNotInventUnavailableDetails() throws {
        let error = LanguageModelSession.GenerationError.exceededContextWindowSize(
            .init(debugDescription: "Legacy context overflow")
        )
        let projection = try XCTUnwrap(FoundationLabModelErrorProjection.project(error))

        XCTAssertEqual(projection.category, .contextSizeExceeded)
        XCTAssertNil(projection.contextSize)
        XCTAssertNil(projection.attemptedTokenCount)
        XCTAssertNil(projection.resetDate)
        XCTAssertNil(projection.capability)
        XCTAssertTrue(projection.isContextOverflow)
        XCTAssertTrue(FoundationLabModelErrorProjection.isContextOverflow(error))

        let encoded = try JSONEncoder().encode(projection)
        let decoded = try JSONDecoder().decode(
            FoundationLabModelErrorProjection.self,
            from: encoded
        )
        XCTAssertEqual(decoded, projection)
        let payload = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertFalse(payload.contains("Legacy context overflow"))
    }

    func testGenerationErrorCategoriesRemainDistinctFromOverflow() throws {
        let fixtures: [(
            LanguageModelSession.GenerationError,
            FoundationLabModelErrorProjection.Category
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
            let projection = try XCTUnwrap(FoundationLabModelErrorProjection.project(error))
            XCTAssertEqual(projection.category, expectedCategory)
            XCTAssertFalse(FoundationLabModelErrorProjection.isContextOverflow(error))
        }
    }

    func testUnrelatedErrorsAreNotProjectedAsOverflow() {
        struct UnrelatedError: Error {}
        let error = UnrelatedError()

        XCTAssertNil(FoundationLabModelErrorProjection.project(error))
        XCTAssertFalse(FoundationLabModelErrorProjection.isContextOverflow(error))
    }
}
