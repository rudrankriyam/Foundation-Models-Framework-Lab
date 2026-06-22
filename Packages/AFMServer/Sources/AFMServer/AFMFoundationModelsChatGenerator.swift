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
            let response = try await session.respond(to: prepared.prompt, options: prepared.options)
            guard !request.toolChoice.requiresInvocation else {
                throw AFMChatGenerationError.requiredToolNotCalled
            }
            let usage = await responseUsage(response, prepared: prepared)
            return AFMChatGenerationResult(
                content: response.content,
                finishReason: finishReason(for: request, usage: usage),
                usage: usage
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
        let responseStream = session.streamResponse(to: prepared.prompt, options: prepared.options)
        var accumulator = AFMSnapshotDeltaAccumulator()

        do {
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
            let usage = await responseUsage(response, prepared: prepared)
            let result = AFMChatGenerationResult(
                content: response.content,
                finishReason: finishReason(for: request, usage: usage),
                usage: usage
            )
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

    private func responseUsage(
        _ response: LanguageModelSession.Response<String>,
        prepared: AFMPreparedChatGeneration
    ) async -> ModelTokenUsage {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, *) {
            return ModelTokenUsage(observing: response.usage)
        }
        #endif

        return await fallbackUsage(input: prepared.inputTranscript, output: response.content)
    }

    private func refusalResult(prepared: AFMPreparedChatGeneration) async -> AFMChatGenerationResult {
        let inputUsage = await prepared.inputTranscript.tokenUsage(using: .default)
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
        let usage = await fallbackUsage(input: prepared.inputTranscript, output: output)
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

    private func fallbackUsage(input: Transcript, output: String) async -> ModelTokenUsage {
        await fallbackUsage(input: input, output: outputEntry(output))
    }

    private func fallbackUsage(input: Transcript, output: Transcript.Entry) async -> ModelTokenUsage {
        async let inputUsage = input.tokenUsage(using: .default)
        async let outputUsage = output.tokenUsage(using: .default)
        let (resolvedInput, resolvedOutput) = await (inputUsage, outputUsage)
        let measurement: ModelTokenUsage.Measurement =
            resolvedInput.measurement == .tokenized && resolvedOutput.measurement == .tokenized
            ? .tokenized
            : .estimated
        return ModelTokenUsage(
            input: .init(totalTokenCount: resolvedInput.totalTokenCount),
            output: .init(totalTokenCount: resolvedOutput.totalTokenCount),
            measurement: measurement,
            scope: .response
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
}

struct AFMPreparedChatGeneration {
    let transcript: Transcript
    let prompt: Prompt
    let inputTranscript: Transcript
    let options: GenerationOptions
}

enum AFMChatTranscriptBuilder {
    static func prepare(
        _ request: AFMChatGenerationRequest,
        toolDefinitions: [Transcript.ToolDefinition] = []
    ) throws -> AFMPreparedChatGeneration {
        guard !request.messages.isEmpty else {
            throw AFMChatGenerationError.unsupportedInput
        }
        let finalMessage = request.messages[request.messages.index(before: request.messages.endIndex)]
        let history = finalMessage.role == .user ? request.messages.dropLast() : request.messages[...]
        let entries = try transcriptEntries(for: history)
        let promptContent = activePromptContent(for: finalMessage)
        let prompt = Prompt(promptContent)
        let inputPrompt = Transcript.Prompt(segments: segments(promptContent))
        let inputEntries = adding(toolDefinitions, to: entries) + [.prompt(inputPrompt)]
        let inputTranscript = Transcript(entries: inputEntries)
        let transcript = Transcript(entries: entries)
        return AFMPreparedChatGeneration(
            transcript: transcript,
            prompt: prompt,
            inputTranscript: inputTranscript,
            options: try generationOptions(for: request)
        )
    }

    private static func adding(
        _ toolDefinitions: [Transcript.ToolDefinition],
        to entries: [Transcript.Entry]
    ) -> [Transcript.Entry] {
        guard !toolDefinitions.isEmpty else { return entries }
        var result = entries
        if let first = result.first, case .instructions(let instructions) = first {
            result[0] = .instructions(
                .init(
                    id: instructions.id,
                    segments: instructions.segments,
                    toolDefinitions: instructions.toolDefinitions + toolDefinitions
                )
            )
        } else {
            result.insert(
                .instructions(.init(segments: [], toolDefinitions: toolDefinitions)),
                at: 0
            )
        }
        return result
    }

    static func segments(_ content: [String]) -> [Transcript.Segment] {
        content.map { .text(.init(content: $0)) }
    }

    private static func transcriptEntries(
        for messages: ArraySlice<AFMChatMessage>
    ) throws -> [Transcript.Entry] {
        var entries: [Transcript.Entry] = []
        var toolNames: [String: String] = [:]
        let instructionMessages = messages.prefix { $0.role == .system || $0.role == .developer }
        let instructionSegments = instructionMessages.flatMap { segments($0.contentSegments ?? []) }
        if !instructionSegments.isEmpty {
            entries.append(.instructions(.init(segments: instructionSegments, toolDefinitions: [])))
        }

        for message in messages.dropFirst(instructionMessages.count) {
            try append(message, to: &entries, toolNames: &toolNames)
        }
        return entries
    }

    private static func append(
        _ message: AFMChatMessage,
        to entries: inout [Transcript.Entry],
        toolNames: inout [String: String]
    ) throws {
        switch message.role {
        case .system, .developer:
            break
        case .user:
            entries.append(.prompt(.init(segments: segments(message.contentSegments ?? []))))
        case .assistant:
            try appendAssistant(message, to: &entries, toolNames: &toolNames)
        case .tool:
            try appendToolOutput(message, to: &entries, toolNames: toolNames)
        }
    }

    private static func appendAssistant(
        _ message: AFMChatMessage,
        to entries: inout [Transcript.Entry],
        toolNames: inout [String: String]
    ) throws {
        if let content = message.contentSegments {
            entries.append(.response(.init(assetIDs: [], segments: segments(content))))
        }
        guard !message.toolCalls.isEmpty else { return }
        let calls = try message.toolCalls.map { call in
            toolNames[call.id] = call.name
            return Transcript.ToolCall(
                id: call.id,
                toolName: call.name,
                arguments: try GeneratedContent(json: call.arguments)
            )
        }
        entries.append(.toolCalls(.init(calls)))
    }

    private static func appendToolOutput(
        _ message: AFMChatMessage,
        to entries: inout [Transcript.Entry],
        toolNames: [String: String]
    ) throws {
        guard let identifier = message.toolCallID,
              let toolName = message.name ?? toolNames[identifier] else {
            throw AFMChatGenerationError.unsupportedInput
        }
        entries.append(
            .toolOutput(
                .init(
                    id: identifier,
                    toolName: toolName,
                    segments: segments(message.contentSegments ?? [])
                )
            )
        )
    }

    private static func activePromptContent(for finalMessage: AFMChatMessage) -> [String] {
        if finalMessage.role == .user {
            return finalMessage.contentSegments ?? []
        }
        return [""]
    }

    private static func generationOptions(for request: AFMChatGenerationRequest) throws -> GenerationOptions {
        let sampling = request.topP.map { GenerationOptions.SamplingMode.random(probabilityThreshold: $0) }
        #if compiler(>=6.4)
        var options = GenerationOptions(
            samplingMode: sampling,
            temperature: request.temperature,
            maximumResponseTokens: request.maximumCompletionTokens
        )
        if #available(iOS 27.0, macOS 27.0, *) {
            switch request.toolChoice {
            case .auto:
                options.toolCallingMode = .allowed
            case .none:
                options.toolCallingMode = .disallowed
            case .required, .function:
                options.toolCallingMode = .required
            }
        } else if request.toolChoice.requiresInvocation {
            throw AFMChatGenerationError.unsupportedToolChoice
        }
        return options
        #else
        guard !request.toolChoice.requiresInvocation else {
            throw AFMChatGenerationError.unsupportedToolChoice
        }
        return GenerationOptions(
            sampling: sampling,
            temperature: request.temperature,
            maximumResponseTokens: request.maximumCompletionTokens
        )
        #endif
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
