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

@Test("Foundation Models generator passes validated capture tools to tool-aware builders")
func foundationModelsGeneratorForwardsCaptureTools() async throws {
    let probe = AFMSessionBuilderProbe()
    let generator = AFMFoundationModelsChatGenerator(
        toolSessionBuilder: { modelIdentifier, tools, _ in
            probe.record("\(modelIdentifier):\(tools.count):\(tools.first?.name ?? "missing")")
            throw AFMSessionBuilderTestError.expected
        }
    )
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Call ping"])],
        tools: [
            .init(
                name: "ping",
                parameters: .init(type: "object", additionalProperties: false)
            )
        ]
    )

    await #expect(throws: AFMSessionBuilderTestError.expected) {
        try await generator.generate(request)
    }
    #expect(probe.modelIdentifier == "system:1:ping")
}

@Test("Tool choice none does not register caller-declared tools")
func foundationModelsGeneratorOmitsDisabledTools() async throws {
    let probe = AFMSessionBuilderProbe()
    let generator = AFMFoundationModelsChatGenerator(
        toolSessionBuilder: { modelIdentifier, tools, _ in
            probe.record("\(modelIdentifier):\(tools.count)")
            throw AFMSessionBuilderTestError.expected
        }
    )
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Do not call ping"])],
        tools: [.init(name: "ping")],
        toolChoice: .none
    )

    await #expect(throws: AFMSessionBuilderTestError.expected) {
        try await generator.generate(request)
    }
    #expect(probe.modelIdentifier == "system:0")
}

#if compiler(<6.4)
@Test("Forced tool choices reject precisely when the compiler lacks a public required mode")
func foundationModelsGeneratorRejectsForcedToolsOnXcode26() throws {
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Call ping"])],
        tools: [.init(name: "ping")],
        toolChoice: .required
    )

    #expect(throws: AFMChatGenerationError.unsupportedToolChoice) {
        try AFMChatTranscriptBuilder.prepare(request)
    }
}
#endif

#if compiler(>=6.4)
@Test("Forced tool choices use the public OS 27 required mode")
func foundationModelsGeneratorRequiresToolsOnOS27() throws {
    guard #available(macOS 27.0, *) else { return }
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Call ping"])],
        tools: [.init(name: "ping")],
        toolChoice: .required
    )

    let prepared = try AFMChatTranscriptBuilder.prepare(request)
    #expect(prepared.options.toolCallingMode?.kind == .required)
}

@Test("Foundation Models generator preserves requested reasoning level")
func foundationModelsGeneratorPreservesReasoningLevel() throws {
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Think carefully"])],
        reasoningLevel: .moderate
    )

    let prepared = try AFMChatTranscriptBuilder.prepare(request)
    #expect(prepared.reasoningLevel == .moderate)
}
#endif

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
