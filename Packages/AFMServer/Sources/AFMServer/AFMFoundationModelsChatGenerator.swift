import Foundation
import FoundationModels
import FoundationModelsKit

public struct AFMFoundationModelsChatGenerator: AFMChatCompletionGenerating {
    private let sessionBuilder: AFMFoundationModelsToolSessionBuilder

    public init() {
        sessionBuilder = { requestedModelIdentifier, tools, transcript in
            guard requestedModelIdentifier == "system" else {
                throw AFMChatGenerationError.modelUnavailable
            }
            return LanguageModelSession(model: .default, tools: tools, transcript: transcript)
        }
    }

    public init(sessionBuilder: @escaping AFMFoundationModelsSessionBuilder) {
        self.sessionBuilder = { requestedModelIdentifier, tools, transcript in
            guard tools.isEmpty else {
                throw AFMChatGenerationError.unsupportedInput
            }
            return try sessionBuilder(requestedModelIdentifier, transcript)
        }
    }

    public init(toolSessionBuilder: @escaping AFMFoundationModelsToolSessionBuilder) {
        sessionBuilder = toolSessionBuilder
    }

    public func generate(_ request: AFMChatGenerationRequest) async throws -> AFMChatGenerationResult {
        let toolRuntime = try AFMChatToolRuntime(request: request)
        let prepared = try AFMChatTranscriptBuilder.prepare(
            request,
            toolDefinitions: toolRuntime.transcriptDefinitions
        )
        let session = try sessionBuilder(request.model, toolRuntime.tools, prepared.transcript)

        do {
            let result = try await generationResult(
                for: request,
                prepared: prepared,
                session: session
            )
            guard !request.toolChoice.requiresInvocation else {
                throw AFMChatGenerationError.requiredToolNotCalled
            }
            return result
        } catch let error as LanguageModelSession.ToolCallError where error.isAFMChatToolCapture {
            return try await toolCallResult(runtime: toolRuntime, prepared: prepared)
        } catch {
            if Self.isRefusal(error) {
                return await refusalResult(prepared: prepared)
            }
            throw Self.mappedError(error)
        }
    }

    public func stream(
        _ request: AFMChatGenerationRequest,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        let toolRuntime = try AFMChatToolRuntime(request: request)
        let prepared = try AFMChatTranscriptBuilder.prepare(
            request,
            toolDefinitions: toolRuntime.transcriptDefinitions
        )
        let session = try sessionBuilder(request.model, toolRuntime.tools, prepared.transcript)

        do {
            if prepared.responseSchema != nil {
                return try await streamStructuredResponse(
                    request: request,
                    prepared: prepared,
                    session: session,
                    emitting: event
                )
            }
            return try await streamTextResponse(
                request: request,
                prepared: prepared,
                session: session,
                toolRuntime: toolRuntime,
                emitting: event
            )
        } catch let error as LanguageModelSession.ToolCallError where error.isAFMChatToolCapture {
            return try await toolCallResult(runtime: toolRuntime, prepared: prepared)
        } catch {
            if Self.isRefusal(error) {
                return await refusalResult(prepared: prepared)
            }
            throw Self.mappedError(error)
        }
    }
}

private extension AFMFoundationModelsChatGenerator {
    func streamStructuredResponse(
        request: AFMChatGenerationRequest,
        prepared: AFMPreparedChatGeneration,
        session: LanguageModelSession,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        let result = try await generationResult(for: request, prepared: prepared, session: session)
        try Task.checkCancellation()
        if let content = result.content, !content.isEmpty {
            try await event(.contentDelta(content))
        }
        guard !request.toolChoice.requiresInvocation else {
            throw AFMChatGenerationError.requiredToolNotCalled
        }
        return result
    }

    func streamTextResponse(
        request: AFMChatGenerationRequest,
        prepared: AFMPreparedChatGeneration,
        session: LanguageModelSession,
        toolRuntime: AFMChatToolRuntime,
        emitting event: @escaping @Sendable (AFMChatGenerationEvent) async throws -> Void
    ) async throws -> AFMChatGenerationResult {
        let responseStream = session.streamResponse(to: prepared.prompt, options: prepared.options)
        var accumulator = AFMSnapshotDeltaAccumulator()
        for try await snapshot in responseStream {
            try Task.checkCancellation()
            let delta = try accumulator.append(snapshot: snapshot.content)
            if !toolRuntime.isActive, !delta.isEmpty {
                try await event(.contentDelta(delta))
            }
        }

        try Task.checkCancellation()
        let response = try await responseStream.collect()
        let finalDelta = try accumulator.append(snapshot: response.content)
        if !toolRuntime.isActive, !finalDelta.isEmpty {
            try await event(.contentDelta(finalDelta))
        }
        if toolRuntime.isActive, !response.content.isEmpty {
            try await event(.contentDelta(response.content))
        }
        try Task.checkCancellation()
        guard !request.toolChoice.requiresInvocation else {
            throw AFMChatGenerationError.requiredToolNotCalled
        }
        let usage = await responseUsage(
            response,
            prepared: prepared,
            fallbackOutput: outputEntry(response.content)
        )
        return AFMChatGenerationResult(
            content: response.content,
            finishReason: finishReason(for: request, usage: usage),
            usage: usage
        )
    }

    func generationResult(
        for request: AFMChatGenerationRequest,
        prepared: AFMPreparedChatGeneration,
        session: LanguageModelSession
    ) async throws -> AFMChatGenerationResult {
        if let responseSchema = prepared.responseSchema {
            let response = try await session.respond(
                to: prepared.prompt,
                schema: responseSchema.generationSchema,
                includeSchemaInPrompt: true,
                options: prepared.options
            )
            let content = response.content.jsonString
            let usage = await responseUsage(
                response,
                prepared: prepared,
                fallbackOutput: structuredOutputEntry(
                    response.content,
                    source: responseSchema.name
                )
            )
            return AFMChatGenerationResult(
                content: content,
                finishReason: finishReason(for: request, usage: usage),
                usage: usage
            )
        }

        let response = try await session.respond(to: prepared.prompt, options: prepared.options)
        let usage = await responseUsage(
            response,
            prepared: prepared,
            fallbackOutput: outputEntry(response.content)
        )
        return AFMChatGenerationResult(
            content: response.content,
            finishReason: finishReason(for: request, usage: usage),
            usage: usage
        )
    }

    private func responseUsage<Content>(
        _ response: LanguageModelSession.Response<Content>,
        prepared: AFMPreparedChatGeneration,
        fallbackOutput: Transcript.Entry
    ) async -> ModelTokenUsage where Content: Generable {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, *) {
            return ModelTokenUsage(observing: response.usage)
        }
        #endif

        return await fallbackUsage(prepared: prepared, output: fallbackOutput)
    }

    private func refusalResult(prepared: AFMPreparedChatGeneration) async -> AFMChatGenerationResult {
        let inputUsage = await fallbackInputUsage(prepared: prepared)
        let usage = ModelTokenUsage(
            input: .init(totalTokenCount: inputUsage.totalTokenCount),
            output: .init(totalTokenCount: 0),
            measurement: inputUsage.measurement,
            scope: .response
        )
        return AFMChatGenerationResult(
            content: nil,
            refusal: "The model declined to answer this request.",
            finishReason: .contentFilter,
            usage: usage
        )
    }

    private func toolCallResult(
        runtime: AFMChatToolRuntime,
        prepared: AFMPreparedChatGeneration
    ) async throws -> AFMChatGenerationResult {
        let calls = try await runtime.capturedCalls()
        guard !calls.isEmpty else {
            throw AFMChatGenerationError.unsupportedInput
        }
        let output = try toolCallsEntry(calls)
        let usage = await fallbackUsage(prepared: prepared, output: output)
        return AFMChatGenerationResult(
            content: nil,
            finishReason: .toolCalls,
            usage: usage,
            toolCalls: calls
        )
    }

    private func finishReason(
        for request: AFMChatGenerationRequest,
        usage: ModelTokenUsage
    ) -> AFMChatFinishReason {
        guard let limit = request.maximumCompletionTokens,
              let output = usage.output,
              output.totalTokenCount >= limit,
              output.totalTokenCount > 0 else {
            return .stop
        }
        return .length
    }

    private func fallbackUsage(
        prepared: AFMPreparedChatGeneration,
        output: Transcript.Entry
    ) async -> ModelTokenUsage {
        async let inputUsage = fallbackInputUsage(prepared: prepared)
        async let outputUsage = output.tokenUsage(using: .default)
        let (resolvedInput, resolvedOutput) = await (inputUsage, outputUsage)
        return Self.responseScopedFallbackUsage(
            input: resolvedInput,
            output: resolvedOutput
        )
    }

    private func fallbackInputUsage(
        prepared: AFMPreparedChatGeneration
    ) async -> ModelTokenUsage {
        let usage = await prepared.inputTranscript.tokenUsage(using: .default)
        return Self.schemaAwareFallbackInputUsage(
            transcriptUsage: usage,
            schemaText: prepared.responseSchema?.fallbackTokenText
        )
    }

    private func outputEntry(_ content: String) -> Transcript.Entry {
        .response(.init(assetIDs: [], segments: AFMChatTranscriptBuilder.segments([content])))
    }

    private func toolCallsEntry(_ calls: [AFMChatToolCall]) throws -> Transcript.Entry {
        let transcriptCalls = try calls.map { call in
            Transcript.ToolCall(
                id: call.id,
                toolName: call.name,
                arguments: try GeneratedContent(json: call.arguments)
            )
        }
        return .toolCalls(.init(transcriptCalls))
    }

    private func structuredOutputEntry(
        _ content: GeneratedContent,
        source: String
    ) -> Transcript.Entry {
        .response(
            .init(
                assetIDs: [],
                segments: [.structure(.init(source: source, content: content))]
            )
        )
    }
}

extension AFMFoundationModelsChatGenerator {
    static func schemaAwareFallbackInputUsage(
        transcriptUsage: ModelTokenUsage,
        schemaText: String?
    ) -> ModelTokenUsage {
        // Apple's tokenizer receives the prompt responseFormat in the transcript.
        // Only the text estimator needs the schema added separately.
        guard transcriptUsage.measurement == .estimated, let schemaText else {
            return transcriptUsage
        }
        return ModelTokenUsage(
            inputTokenCount: transcriptUsage.input.totalTokenCount + estimateTokens(from: schemaText),
            measurement: .estimated,
            scope: transcriptUsage.scope
        )
    }

    static func responseScopedFallbackUsage(
        input: ModelTokenUsage,
        output: ModelTokenUsage
    ) -> ModelTokenUsage {
        let measurement: ModelTokenUsage.Measurement =
            input.measurement == .tokenized && output.measurement == .tokenized
            ? .tokenized
            : .estimated
        return ModelTokenUsage(
            input: .init(totalTokenCount: input.totalTokenCount),
            output: .init(totalTokenCount: output.totalTokenCount),
            measurement: measurement,
            scope: .response
        )
    }
}

private extension AFMFoundationModelsChatGenerator {
    static func isRefusal(_ error: Error) -> Bool {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, *), let modelError = error as? LanguageModelError {
            if case .refusal = modelError {
                return true
            }
        }
        #endif
        if let generationError = error as? LanguageModelSession.GenerationError {
            if case .refusal = generationError {
                return true
            }
        }
        return false
    }

    static func mappedError(_ error: Error) -> Error {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, *), let mapped = mapModernError(error) {
            return mapped
        }
        #endif
        return mapLegacyError(error) ?? error
    }

    static func mapLegacyError(_ error: Error) -> AFMChatGenerationError? {
        guard let generationError = error as? LanguageModelSession.GenerationError else { return nil }
        switch generationError {
        case .exceededContextWindowSize:
            return .contextLengthExceeded
        case .assetsUnavailable:
            return .modelUnavailable
        case .guardrailViolation, .refusal:
            return .safetyViolation
        case .rateLimited:
            return .rateLimited
        case .concurrentRequests:
            return .concurrentRequest
        case .unsupportedGuide, .unsupportedLanguageOrLocale, .decodingFailure:
            return .unsupportedInput
        @unknown default:
            return nil
        }
    }
}

#if compiler(>=6.4)
extension AFMFoundationModelsChatGenerator {
    @available(iOS 27.0, macOS 27.0, *)
    static func mapModernError(_ error: Error) -> AFMChatGenerationError? {
        if error is SystemLanguageModel.Error {
            return .modelUnavailable
        }
        if let sessionError = error as? LanguageModelSession.Error {
            return mapModernSessionError(sessionError)
        }
        guard let modelError = error as? LanguageModelError else { return nil }
        switch modelError {
        case .contextSizeExceeded:
            return .contextLengthExceeded
        case .rateLimited:
            return .rateLimited
        case .guardrailViolation, .refusal:
            return .safetyViolation
        case .timeout:
            return .timedOut
        case .unsupportedCapability,
             .unsupportedTranscriptContent,
             .unsupportedGenerationGuide,
             .unsupportedLanguageOrLocale:
            return .unsupportedInput
        @unknown default:
            return nil
        }
    }

    @available(iOS 27.0, macOS 27.0, *)
    private static func mapModernSessionError(
        _ error: LanguageModelSession.Error
    ) -> AFMChatGenerationError? {
        switch error {
        case .concurrentRequests:
            return .concurrentRequest
        case .transcriptMutationWhileResponding:
            return nil
        @unknown default:
            return nil
        }
    }
}
#endif
