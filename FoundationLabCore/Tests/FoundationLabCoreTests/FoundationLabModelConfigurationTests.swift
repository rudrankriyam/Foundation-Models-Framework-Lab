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
        XCTAssertEqual(FoundationModelUseCase.contentTagging.rawValue, "content-tagging")
        XCTAssertEqual(
            FoundationModelGuardrails.permissiveContentTransformations.rawValue,
            "permissiveContentTransformations"
        )
    }

    func testStructuredRequestPreservesAdapterAndGenerationControls() {
        let adapterURL = URL(fileURLWithPath: "/tmp/Test.fmadapter")
        let options = FoundationModelGenerationOptions(
            sampling: .greedy,
            temperature: 0.2,
            maximumResponseTokens: 128
        )
        let request = FoundationModelStructuredGenerationRequest<ModelConfigurationTestOutput>(
            prompt: "Extract a value",
            adapterURL: adapterURL,
            generationOptions: options,
            includeSchemaInPrompt: false,
            context: FoundationModelInvocationContext(source: .cli)
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
                error as? FoundationModelsKitError,
                .invalidRequest("Foundation Models adapters only support the framework's default guardrails.")
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
    func testAdapterConversationEngineRejectsPrivateCloudRuntime() {
        XCTAssertThrowsError(
            try FoundationModelConversationEngine(
                configuration: makeConversationConfiguration(
                    modelRuntime: .privateCloudCompute
                ),
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationModelsKitError,
                .invalidRequest("Foundation Models adapters only support the on-device runtime.")
            )
        }
    }

    @MainActor
    func testAdapterConversationEngineRejectsReasoningLevel() {
        XCTAssertThrowsError(
            try FoundationModelConversationEngine(
                configuration: makeConversationConfiguration(reasoningLevel: .deep),
                adapterURL: URL(fileURLWithPath: "/tmp/Test.fmadapter")
            )
        ) { error in
            XCTAssertEqual(
                error as? FoundationModelsKitError,
                .invalidRequest("Foundation Models adapters do not support Private Cloud Compute reasoning levels.")
            )
        }
    }

    private func makeConversationConfiguration(
        modelRuntime: FoundationModelRuntime = .onDevice,
        reasoningLevel: FoundationModelReasoningLevel = .none
    ) -> FoundationModelConversationConfiguration {
        FoundationModelConversationConfiguration(
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
