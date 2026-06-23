#if compiler(>=6.4)
import Foundation
import FoundationModels
import XCTest
@testable import FoundationLabCore

@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
final class FoundationLabModelErrorProjectionModernTests: XCTestCase {
    func testLanguageModelErrorPreservesStableContextAndRateLimitDetails() throws {
        let resetDate = Date(timeIntervalSince1970: 1_800_000_000)
        let overflowContext = FoundationModels.LanguageModelError.ContextSizeExceeded(
            contextSize: 8_192,
            tokenCount: 8_321,
            debugDescription: "Modern context overflow",
            metadata: ["fixture": "context-overflow"]
        )
        let overflow = FoundationModels.LanguageModelError.contextSizeExceeded(overflowContext)
        let rateLimit = FoundationModels.LanguageModelError.rateLimited(
            .init(
                resetDate: resetDate,
                debugDescription: "Modern rate limit",
                metadata: ["scope": "model"]
            )
        )

        let overflowProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(overflow)
        )
        let rateLimitProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(rateLimit)
        )

        XCTAssertEqual(overflowProjection.category, .contextSizeExceeded)
        XCTAssertEqual(overflowProjection.contextSize, 8_192)
        XCTAssertEqual(overflowProjection.attemptedTokenCount, 8_321)
        XCTAssertTrue(FoundationLabModelErrorProjection.isContextOverflow(overflow))
        XCTAssertEqual(rateLimitProjection.category, .rateLimited)
        XCTAssertEqual(rateLimitProjection.resetDate, resetDate)
        XCTAssertFalse(FoundationLabModelErrorProjection.isContextOverflow(rateLimit))

        let encoded = try JSONEncoder().encode(overflowProjection)
        let decoded = try JSONDecoder().decode(
            FoundationLabModelErrorProjection.self,
            from: encoded
        )
        XCTAssertEqual(decoded, overflowProjection)
        let payload = try XCTUnwrap(String(data: encoded, encoding: .utf8))
        XCTAssertFalse(payload.contains("Modern context overflow"))
        XCTAssertFalse(payload.contains("context-overflow"))
    }

    func testLanguageModelErrorPreservesPolicyAndCapabilityCategories() throws {
        let guardrail = FoundationModels.LanguageModelError.guardrailViolation(
            .init(debugDescription: "Modern guardrail", metadata: ["policy": "safety"])
        )
        let refusal = FoundationModels.LanguageModelError.refusal(
            .init(
                explanation: "The request could not be completed.",
                debugDescription: "Modern refusal",
                metadata: ["reason": "policy"]
            )
        )
        let unsupportedCapability = FoundationModels.LanguageModelError.unsupportedCapability(
            .init(
                capability: .reasoning,
                debugDescription: "Reasoning unsupported",
                metadata: ["model": "system"]
            )
        )

        let guardrailProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(guardrail)
        )
        let refusalProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(refusal)
        )
        let capabilityProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(unsupportedCapability)
        )

        XCTAssertEqual(guardrailProjection.category, .guardrailViolation)
        XCTAssertEqual(refusalProjection.category, .refusal)
        XCTAssertEqual(capabilityProjection.category, .unsupportedCapability)
        XCTAssertEqual(capabilityProjection.capability, .reasoning)
    }

    func testLanguageModelErrorPreservesAdditionalPublicDetails() throws {
        let unsupportedContent = FoundationModels.LanguageModelError.unsupportedTranscriptContent(
            .init(unsupportedContent: [], debugDescription: "Unsupported transcript")
        )
        let unsupportedGuide = FoundationModels.LanguageModelError.unsupportedGenerationGuide(
            .init(schemaName: "Recipe", debugDescription: "Unsupported guide")
        )
        let unsupportedLanguage = FoundationModels.LanguageModelError.unsupportedLanguageOrLocale(
            .init(languageCode: Locale.LanguageCode("fr"), debugDescription: "Unsupported language")
        )
        let timeout = FoundationModels.LanguageModelError.timeout(
            .init(debugDescription: "Timed out")
        )
        let parsingError = GeneratedContent.ParsingError(
            rawContent: "{}",
            underlyingError: FoundationLabCoreError.invalidRequest("Fixture parsing failure"),
            debugDescription: "Parsing failed"
        )

        let contentProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(unsupportedContent)
        )
        let guideProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(unsupportedGuide)
        )
        let languageProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(unsupportedLanguage)
        )
        let timeoutProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(timeout)
        )
        let parsingProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(parsingError)
        )

        XCTAssertEqual(contentProjection.category, .unsupportedTranscriptContent)
        XCTAssertEqual(contentProjection.unsupportedTranscriptEntryCount, 0)
        XCTAssertEqual(guideProjection.category, .unsupportedGenerationGuide)
        XCTAssertEqual(guideProjection.schemaName, "Recipe")
        XCTAssertEqual(languageProjection.category, .unsupportedLanguageOrLocale)
        XCTAssertEqual(languageProjection.languageCode, "fr")
        XCTAssertEqual(timeoutProjection.category, .timeout)
        XCTAssertEqual(parsingProjection.category, .decodingFailure)

        let payload = try XCTUnwrap(
            String(data: try JSONEncoder().encode(parsingProjection), encoding: .utf8)
        )
        XCTAssertFalse(payload.contains("Fixture parsing failure"))
        XCTAssertFalse(payload.contains("Parsing failed"))
    }

    func testRelatedModelErrorsUseStableCategories() throws {
        let resetDate = Date(timeIntervalSince1970: 1_800_000_000)
        let fixtures: [(any Error, FoundationLabModelErrorProjection.Category)] = [
            (
                SystemLanguageModel.Error.assetsUnavailable(
                    .init(debugDescription: "Assets unavailable")
                ),
                .assetsUnavailable
            ),
            (LanguageModelSession.Error.concurrentRequests, .concurrentRequests),
            (
                LanguageModelSession.Error.transcriptMutationWhileResponding,
                .transcriptMutationWhileResponding
            ),
            (
                PrivateCloudComputeLanguageModel.Error.networkFailure(
                    .init(debugDescription: "Network failure")
                ),
                .networkFailure
            ),
            (
                PrivateCloudComputeLanguageModel.Error.quotaLimitReached(
                    .init(resetDate: resetDate, debugDescription: "Quota reached")
                ),
                .quotaLimitReached
            ),
            (
                PrivateCloudComputeLanguageModel.Error.serviceUnavailable(
                    .init(debugDescription: "Service unavailable")
                ),
                .serviceUnavailable
            )
        ]

        for (error, expectedCategory) in fixtures {
            let projection = try XCTUnwrap(FoundationLabModelErrorProjection.project(error))
            XCTAssertEqual(projection.category, expectedCategory)
            XCTAssertFalse(projection.isContextOverflow)
        }

        let quotaProjection = try XCTUnwrap(
            FoundationLabModelErrorProjection.project(fixtures[4].0)
        )
        XCTAssertEqual(quotaProjection.resetDate, resetDate)
        XCTAssertEqual(quotaProjection.hasQuotaLimitIncreaseSuggestion, false)
    }
}
#endif
