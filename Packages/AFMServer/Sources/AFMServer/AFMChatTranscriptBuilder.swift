import FoundationModels

enum AFMChatTranscriptBuilder {
    static func prepare(_ request: AFMChatGenerationRequest) throws -> AFMPreparedChatGeneration {
        guard !request.messages.isEmpty else {
            throw AFMChatGenerationError.unsupportedInput
        }
        let finalMessage = request.messages[request.messages.index(before: request.messages.endIndex)]
        let history = finalMessage.role == .user ? request.messages.dropLast() : request.messages[...]
        let entries = try transcriptEntries(for: history)
        let promptContent = activePromptContent(for: finalMessage)
        let prompt = Prompt(promptContent)
        let options = generationOptions(for: request)
        let responseSchema = try preparedResponseSchema(for: request.responseFormat)
        let transcriptResponseFormat = responseSchema.map {
            Transcript.ResponseFormat(schema: $0.generationSchema)
        }
        let inputPrompt = Transcript.Prompt(
            segments: segments(promptContent),
            options: options,
            responseFormat: transcriptResponseFormat
        )
        let inputTranscript = Transcript(entries: entries + [.prompt(inputPrompt)])
        let transcript = Transcript(entries: entries)
        return AFMPreparedChatGeneration(
            transcript: transcript,
            prompt: prompt,
            inputTranscript: inputTranscript,
            options: options,
            responseSchema: responseSchema
        )
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

    private static func preparedResponseSchema(
        for responseFormat: AFMChatResponseFormat?
    ) throws -> AFMPreparedResponseSchema? {
        guard case .jsonSchema(let responseSchema)? = responseFormat else {
            return nil
        }
        let generationSchema = try responseSchema.generationSchema()
        return AFMPreparedResponseSchema(
            name: responseSchema.name,
            generationSchema: generationSchema,
            fallbackTokenText: generationSchema.debugDescription
        )
    }

    private static func generationOptions(for request: AFMChatGenerationRequest) -> GenerationOptions {
        let sampling = request.topP.map { GenerationOptions.SamplingMode.random(probabilityThreshold: $0) }
        #if compiler(>=6.4)
        return GenerationOptions(
            samplingMode: sampling,
            temperature: request.temperature,
            maximumResponseTokens: request.maximumCompletionTokens
        )
        #else
        return GenerationOptions(
            sampling: sampling,
            temperature: request.temperature,
            maximumResponseTokens: request.maximumCompletionTokens
        )
        #endif
    }
}
