import Foundation
import XCTest
@testable import FoundationLabCore

final class FoundationLabExperimentTests: XCTestCase {
    func testConfigurationCodableRoundTripPreservesExperiment() throws {
        let timestamp = Date(timeIntervalSince1970: 1_750_000_000)
        let identifier = try XCTUnwrap(UUID(uuidString: "3A2DDB08-2959-48F1-8FD5-EF53F4446403"))
        let configuration = FoundationLabExperimentConfiguration(
            id: identifier,
            name: "Weather assistant",
            summary: "Answers weather questions using live data.",
            prompt: "Do I need an umbrella in Cupertino?",
            instructions: "Answer concisely and cite the tool result.",
            level: .expert,
            kind: .toolUse,
            modelRuntime: .privateCloudCompute,
            reasoningLevel: .moderate,
            generationOptions: FoundationLabGenerationOptions(
                sampling: .randomTop(40, seed: 42),
                temperature: 0.4,
                maximumResponseTokens: 256
            ),
            selectedTools: [.weather, .location],
            createdAt: timestamp,
            modifiedAt: timestamp.addingTimeInterval(120)
        )

        let data = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(
            FoundationLabExperimentConfiguration.self,
            from: data
        )

        XCTAssertEqual(decoded, configuration)
        XCTAssertEqual(decoded.level.displayName, "Expert")
        XCTAssertEqual(decoded.level.systemImage, "graduationcap")
    }

    @MainActor
    func testBuiltInToolCatalogHasUniqueTruthfulMetadata() {
        let tools = FoundationLabBuiltInTool.allCases

        XCTAssertEqual(tools.count, 9)
        XCTAssertEqual(Set(tools.map(\.id)).count, tools.count)
        XCTAssertEqual(Set(tools.map(\.displayName)).count, tools.count)
        XCTAssertEqual(Set(tools.map(\.summary)).count, tools.count)
        XCTAssertEqual(Set(tools.map(\.systemImage)).count, tools.count)
        XCTAssertEqual(Set(tools.map(\.toolName)).count, tools.count)
        XCTAssertTrue(tools.allSatisfy { !$0.summary.isEmpty })
        XCTAssertEqual(tools.map { $0.makeTool().name }, tools.map(\.toolName))
    }

    func testAsNewExperimentRefreshesIdentityAndTimestampsOnly() {
        let originalDate = Date(timeIntervalSince1970: 1_700_000_000)
        let newDate = originalDate.addingTimeInterval(3_600)
        let original = FoundationLabExperimentConfiguration(
            name: "Structured extraction",
            summary: "Extracts typed fields.",
            prompt: "Extract the title and author.",
            instructions: "Return only supported fields.",
            level: .advanced,
            kind: .structuredOutput,
            selectedTools: [.webMetadata],
            createdAt: originalDate
        )

        let copy = original.asNewExperiment(at: newDate)

        XCTAssertNotEqual(copy.id, original.id)
        XCTAssertEqual(copy.createdAt, newDate)
        XCTAssertEqual(copy.modifiedAt, newDate)
        XCTAssertEqual(copy.name, original.name)
        XCTAssertEqual(copy.summary, original.summary)
        XCTAssertEqual(copy.prompt, original.prompt)
        XCTAssertEqual(copy.instructions, original.instructions)
        XCTAssertEqual(copy.level, original.level)
        XCTAssertEqual(copy.kind, original.kind)
        XCTAssertEqual(copy.modelRuntime, original.modelRuntime)
        XCTAssertEqual(copy.reasoningLevel, original.reasoningLevel)
        XCTAssertEqual(copy.generationOptions, original.generationOptions)
        XCTAssertEqual(copy.selectedTools, original.selectedTools)
    }

    func testRunCodableRoundTripAndSuccessSemantics() throws {
        let timestamp = Date(timeIntervalSince1970: 1_750_000_000)
        let configuration = FoundationLabExperimentConfiguration(
            name: "Concise chat",
            prompt: "Explain tool calling.",
            createdAt: timestamp
        )
        let successfulRun = FoundationLabExperimentRun(
            configuration: configuration,
            prompt: configuration.prompt,
            response: "The model selects and invokes a declared tool.",
            startedAt: timestamp,
            duration: 0.75,
            provider: "Apple",
            modelIdentifier: "system-language-model",
            tokenCount: 11,
            tokenUsage: .init(
                input: .init(totalTokenCount: 8, cachedTokenCount: 2),
                output: .init(totalTokenCount: 3, reasoningTokenCount: 1),
                measurement: .observed,
                scope: .response
            )
        )
        let failedRun = FoundationLabExperimentRun(
            configuration: configuration,
            prompt: configuration.prompt,
            response: "",
            startedAt: timestamp,
            duration: 0.1,
            provider: "Apple",
            modelIdentifier: "system-language-model",
            errorMessage: "The model is unavailable."
        )

        XCTAssertTrue(successfulRun.succeeded)
        XCTAssertFalse(failedRun.succeeded)
        XCTAssertEqual(successfulRun.status, .succeeded)
        XCTAssertEqual(failedRun.status, .failed)

        let data = try JSONEncoder().encode(successfulRun)
        let decoded = try JSONDecoder().decode(FoundationLabExperimentRun.self, from: data)
        XCTAssertEqual(decoded, successfulRun)
        XCTAssertEqual(decoded.tokenUsage?.input.cachedTokenCount, 2)
        XCTAssertEqual(decoded.tokenUsage?.output?.reasoningTokenCount, 1)
    }

    func testCancelledRunRoundTripAndLegacyStatusInference() throws {
        let timestamp = Date(timeIntervalSince1970: 1_750_000_000)
        let configuration = FoundationLabExperimentConfiguration(
            name: "Cancelled chat",
            prompt: "Write a long response.",
            createdAt: timestamp
        )
        let cancelledRun = FoundationLabExperimentRun(
            configuration: configuration,
            prompt: configuration.prompt,
            response: "",
            startedAt: timestamp,
            duration: 0.25,
            provider: "Apple",
            modelIdentifier: "system-language-model",
            status: .cancelled
        )

        let encoded = try JSONEncoder().encode(cancelledRun)
        let decoded = try JSONDecoder().decode(FoundationLabExperimentRun.self, from: encoded)
        XCTAssertEqual(decoded.status, .cancelled)
        XCTAssertFalse(decoded.succeeded)

        var legacyObject = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacyObject.removeValue(forKey: "status")
        let legacyData = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacyRun = try JSONDecoder().decode(FoundationLabExperimentRun.self, from: legacyData)
        XCTAssertEqual(legacyRun.status, .succeeded)
    }

}
