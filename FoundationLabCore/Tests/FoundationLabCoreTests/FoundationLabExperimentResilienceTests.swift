import Foundation
import XCTest
@testable import FoundationLabCore

final class FoundationLabExperimentResilienceTests: XCTestCase {
    func testConfigurationNormalizesExecutionInvariants() {
        let options = FoundationLabGenerationOptions(
            sampling: .randomProbabilityThreshold(2, seed: 7),
            temperature: -.infinity,
            maximumResponseTokens: 0
        )
        let highTemperatureConfiguration = FoundationLabExperimentConfiguration(
            name: "Hot configuration",
            generationOptions: FoundationLabGenerationOptions(temperature: 20)
        )
        let configuration = FoundationLabExperimentConfiguration(
            name: "Invalid configuration",
            modelRuntime: .onDevice,
            reasoningLevel: .deep,
            generationOptions: options,
            selectedTools: [.weather, .location, .weather]
        )

        XCTAssertEqual(configuration.reasoningLevel, .none)
        XCTAssertEqual(configuration.selectedTools, [.weather, .location])
        XCTAssertNil(configuration.generationOptions.temperature)
        XCTAssertNil(configuration.generationOptions.maximumResponseTokens)
        XCTAssertEqual(
            configuration.generationOptions.sampling,
            .randomProbabilityThreshold(1, seed: 7)
        )
        XCTAssertEqual(highTemperatureConfiguration.generationOptions.temperature, 2)
    }

    func testConfigurationDecodesLegacyAndUnknownValuesWithSafeDefaults() throws {
        let data = Data(
            """
            {
              "name": "Legacy experiment",
              "level": "future-level",
              "modelRuntime": "onDevice",
              "reasoningLevel": "deep",
              "selectedTools": ["weather", "weather"],
              "generationOptions": { "temperature": "invalid" }
            }
            """.utf8
        )

        let configuration = try JSONDecoder().decode(
            FoundationLabExperimentConfiguration.self,
            from: data
        )

        XCTAssertEqual(configuration.name, "Legacy experiment")
        XCTAssertEqual(configuration.level, .beginner)
        XCTAssertEqual(configuration.reasoningLevel, .none)
        XCTAssertEqual(configuration.selectedTools, [.weather])
        XCTAssertEqual(configuration.generationOptions, FoundationLabGenerationOptions())
        XCTAssertEqual(configuration.modifiedAt, configuration.createdAt)
    }

    func testRunCapturesNormalizedConfigurationAndSafeMetrics() {
        let configuration = FoundationLabExperimentConfiguration(
            name: "Run snapshot",
            prompt: "Template prompt",
            modelRuntime: .onDevice,
            reasoningLevel: .moderate
        )
        let run = FoundationLabExperimentRun(
            configuration: configuration,
            prompt: "Actual prompt",
            response: "Actual response",
            startedAt: Date(timeIntervalSinceReferenceDate: .infinity),
            duration: -.infinity,
            provider: "",
            modelIdentifier: "",
            tokenCount: -1
        )

        XCTAssertEqual(run.configuration.prompt, "Actual prompt")
        XCTAssertEqual(run.configuration.reasoningLevel, .none)
        XCTAssertEqual(run.startedAt, run.configuration.modifiedAt)
        XCTAssertEqual(run.duration, 0)
        XCTAssertEqual(run.provider, "Apple Foundation Models")
        XCTAssertEqual(run.modelIdentifier, "SystemLanguageModel")
        XCTAssertNil(run.tokenCount)
        XCTAssertEqual(run.events.map(\.role), [.user, .assistant])
        XCTAssertEqual(run.events.map(\.text), ["Actual prompt", "Actual response"])
    }

    func testRunDecodesLegacyRecordAndSynthesizesTranscriptEvents() throws {
        let data = Data(
            """
            {
              "configuration": { "name": "Legacy run" },
              "prompt": "Hello",
              "response": "Hi"
            }
            """.utf8
        )

        let run = try JSONDecoder().decode(FoundationLabExperimentRun.self, from: data)

        XCTAssertEqual(run.configuration.name, "Legacy run")
        XCTAssertEqual(run.configuration.prompt, "Hello")
        XCTAssertEqual(run.duration, 0)
        XCTAssertEqual(run.provider, "Apple Foundation Models")
        XCTAssertEqual(run.events.map(\.role), [.user, .assistant])
    }

    func testExperimentEventCodableRoundTripPreservesToolContext() throws {
        let event = FoundationLabExperimentEvent(
            role: .tool,
            kind: .toolResult,
            text: "72 degrees and sunny",
            toolName: "weather",
            timestamp: Date(timeIntervalSince1970: 1_750_000_000)
        )

        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(FoundationLabExperimentEvent.self, from: data)

        XCTAssertEqual(decoded, event)
    }

    func testExperimentEventDecodesFutureMetadataWithoutDroppingRunContext() throws {
        let data = Data(
            """
            {
              "role": "future-role",
              "kind": "future-kind",
              "text": "Preserved context"
            }
            """.utf8
        )

        let event = try JSONDecoder().decode(FoundationLabExperimentEvent.self, from: data)

        XCTAssertEqual(event.role, .system)
        XCTAssertEqual(event.kind, .message)
        XCTAssertEqual(event.text, "Preserved context")
    }
}
