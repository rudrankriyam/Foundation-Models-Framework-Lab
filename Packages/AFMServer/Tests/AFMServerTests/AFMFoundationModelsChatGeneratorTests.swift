import Foundation
import FoundationModels
import FoundationModelsKit
import Testing
@testable import AFMServer

@Test("Foundation Models generator forwards the requested model identifier to its session builder")
func foundationModelsGeneratorForwardsRequestedModel() async throws {
    let probe = AFMSessionBuilderProbe()
    let generator = AFMFoundationModelsChatGenerator { modelIdentifier, _ in
        probe.record(modelIdentifier)
        throw AFMSessionBuilderTestError.expected
    }
    let request = AFMChatGenerationRequest(
        model: "pcc",
        messages: [.init(role: .user, contentSegments: ["Hello"])]
    )

    await #expect(throws: AFMSessionBuilderTestError.expected) {
        try await generator.generate(request)
    }
    #expect(probe.modelIdentifier == "pcc")
}

@Test("Fallback usage preserves tokenized provenance only when both sides are tokenized")
func fallbackUsageProvenance() {
    let tokenizedInput = ModelTokenUsage(inputTokenCount: 8, measurement: .tokenized)
    let tokenizedOutput = ModelTokenUsage(inputTokenCount: 5, measurement: .tokenized)
    let estimatedOutput = ModelTokenUsage(inputTokenCount: 5, measurement: .estimated)

    let tokenized = AFMFoundationModelsChatGenerator.responseScopedFallbackUsage(
        input: tokenizedInput,
        output: tokenizedOutput
    )
    let estimated = AFMFoundationModelsChatGenerator.responseScopedFallbackUsage(
        input: tokenizedInput,
        output: estimatedOutput
    )

    #expect(tokenized.input.totalTokenCount == 8)
    #expect(tokenized.output?.totalTokenCount == 5)
    #expect(tokenized.totalTokenCount == 13)
    #expect(tokenized.measurement == .tokenized)
    #expect(tokenized.scope == .response)
    #expect(estimated.measurement == .estimated)
}

@Test("Schema fallback adds guidance once only when transcript usage is estimated")
func schemaFallbackInputUsage() {
    let schemaText = #"{"type":"object"}"#
    let estimatedTranscript = ModelTokenUsage(
        inputTokenCount: 7,
        measurement: .estimated,
        scope: .context
    )
    let tokenizedTranscript = ModelTokenUsage(
        inputTokenCount: 11,
        measurement: .tokenized,
        scope: .context
    )

    let estimated = AFMFoundationModelsChatGenerator.schemaAwareFallbackInputUsage(
        transcriptUsage: estimatedTranscript,
        schemaText: schemaText
    )
    let tokenized = AFMFoundationModelsChatGenerator.schemaAwareFallbackInputUsage(
        transcriptUsage: tokenizedTranscript,
        schemaText: schemaText
    )

    #expect(estimated.totalTokenCount == 7 + estimateTokens(from: schemaText))
    #expect(estimated.measurement == .estimated)
    #expect(estimated.scope == .context)
    #expect(tokenized == tokenizedTranscript)
}

private final class AFMSessionBuilderProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedModelIdentifier: String?

    var modelIdentifier: String? {
        lock.withLock { recordedModelIdentifier }
    }

    func record(_ modelIdentifier: String) {
        lock.withLock { recordedModelIdentifier = modelIdentifier }
    }
}

private enum AFMSessionBuilderTestError: Error {
    case expected
}
