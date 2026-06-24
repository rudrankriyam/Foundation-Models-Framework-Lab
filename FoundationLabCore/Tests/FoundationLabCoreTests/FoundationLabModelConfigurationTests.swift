import Foundation
import FoundationModels
import FoundationModelsKit
import XCTest
@testable import FoundationLabCore

@Generable
struct ModelConfigurationTestOutput: RuntimeCompatibleGenerable {
    let value: String
}

final class FoundationLabModelConfigurationTests: XCTestCase {
    func testModelOptionsUseStableCommandLineIdentifiers() {
        XCTAssertEqual(FoundationLabModelUseCase.contentTagging.rawValue, "content-tagging")
        XCTAssertEqual(
            FoundationLabGuardrails.permissiveContentTransformations.rawValue,
            "permissiveContentTransformations"
        )
    }

    func testStructuredRequestPreservesAdapterAndGenerationControls() {
        let adapterURL = URL(fileURLWithPath: "/tmp/Test.fmadapter")
        let options = FoundationLabGenerationOptions(
            sampling: .greedy,
            temperature: 0.2,
            maximumResponseTokens: 128
        )
        let request = StructuredGenerationRequest<ModelConfigurationTestOutput>(
            prompt: "Extract a value",
            adapterURL: adapterURL,
            generationOptions: options,
            includeSchemaInPrompt: false,
            context: CapabilityInvocationContext(source: .cli)
        )

        XCTAssertEqual(request.adapterURL, adapterURL)
        XCTAssertEqual(request.generationOptions, options)
        XCTAssertFalse(request.includeSchemaInPrompt)
    }

    func testModelFactoryRejectsCustomGuardrailsForAdapters() {
        XCTAssertThrowsError(
            try FoundationModelsModelFactory.makeModel(
                guardrails: .permissiveContentTransformations,
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest(
                    "Foundation Models adapters only support the framework's default guardrails."
                )
            )
        }
    }

    func testModelFactoryAvailabilityIdentifiesSystemUseCase() throws {
        let availability = try FoundationModelsModelFactory.currentAvailability(
            useCase: .contentTagging
        )

        XCTAssertEqual(availability.metadata.modelIdentifier, "content-tagging")
    }

    @MainActor
    func testAdapterConversationEngineKeepsDefaultGuardrailsWhenRebuilding() {
        let engine = FoundationLabConversationEngine(
            configuration: makeConversationConfiguration(),
            model: .default,
            adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
        )

        engine.rebuild(
            modelRuntime: .privateCloudCompute,
            reasoningLevel: .deep,
            guardrails: .permissiveContentTransformations
        )

        XCTAssertEqual(engine.modelRuntime, .onDevice)
        XCTAssertEqual(engine.reasoningLevel, .none)
        XCTAssertEqual(engine.guardrails, .default)
    }

    @MainActor
    func testAdapterConversationEngineRejectsPrivateCloudRuntime() {
        XCTAssertThrowsError(
            try FoundationLabConversationEngine(
                configuration: makeConversationConfiguration(
                    modelRuntime: .privateCloudCompute
                ),
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest(
                    "Foundation Models adapters only support the on-device runtime."
                )
            )
        }
    }

    @MainActor
    func testAdapterConversationEngineRejectsReasoningLevel() {
        XCTAssertThrowsError(
            try FoundationLabConversationEngine(
                configuration: makeConversationConfiguration(reasoningLevel: .deep),
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationLabCoreError,
                .invalidRequest(
                    "Foundation Models adapters do not support Private Cloud Compute reasoning levels."
                )
            )
        }
    }

    private func makeConversationConfiguration(
        modelRuntime: FoundationLabModelRuntime = .onDevice,
        reasoningLevel: FoundationLabReasoningLevel = .none
    ) -> FoundationLabConversationConfiguration {
        FoundationLabConversationConfiguration(
            baseInstructions: "Answer briefly.",
            summaryInstructions: "Summarize.",
            summaryPromptPreamble: "Summary:",
            conversationUserLabel: "User:",
            conversationAssistantLabel: "Assistant:",
            continuationNote: "Continue.",
            modelRuntime: modelRuntime,
            reasoningLevel: reasoningLevel
        )
    }
}
