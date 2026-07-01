import ArgumentParser
import Foundation
import FoundationModels
import FoundationModelsKit

struct SessionCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Run one-shot, streaming, or multi-turn session flows.",
        discussion: HelpText.session,
        subcommands: [
            SessionRespondCommand.self,
            SessionStreamCommand.self,
            SessionChatCommand.self
        ]
    )
}

struct SessionResponsePayload: Encodable {
    let command: String
    let adapter: String?
    let useCase: String
    let guardrails: String
    let prompt: String?
    let messages: [String]?
    let response: String?
    let exchanges: [AFMConversationExchange]?
    let sessionCount: Int
    let tokenCount: Int
    let tokenUsage: ModelTokenUsage?
    let transcript: [CLITranscriptEntry]?
}

struct SessionRespondCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "respond",
        abstract: "Send one prompt through a fresh session and print the final response."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var promptInput: PromptInputOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "session respond",
                    adapter: adapterPath,
                    prompt: resolvedPrompt.value,
                    promptFile: resolvedPrompt.file,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    toolFiles: toolResolution.references.map { $0.filePath },
                    toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm session respond\nPrompt: \(resolvedPrompt.value)",
                options: resolvedOutput
            )
            return
        }

        let context = SessionCommandContext(
            command: "session respond",
            adapterPath: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            output: resolvedOutput,
            verbose: options.verbose,
            streamingEnabled: false
        )
        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let engine = try await MainActor.run {
            try makeSessionEngine(
                SessionEngineRequest(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools,
                    adapterPath: adapterPath
                )
            )
        }
        let response = try await engine.sendMessage(resolvedPrompt.value, generationOptions: generationOptions)
        let snapshot = await MainActor.run {
            captureSessionSnapshot(engine: engine, includeTranscript: transcriptFlags.transcript)
        }
        try emitRespondResult(
            response: response,
            prompt: resolvedPrompt.value,
            snapshot: snapshot,
            context: context
        )
    }
}

struct SessionStreamCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "stream",
        abstract: "Stream one response from a fresh session as it is generated."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var promptInput: PromptInputOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try emitDryRun(
                prompt: resolvedPrompt,
                adapterPath: adapterPath,
                tools: toolResolution,
                output: resolvedOutput
            )
            return
        }

        let context = SessionCommandContext(
            command: "session stream",
            adapterPath: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            output: resolvedOutput,
            verbose: options.verbose,
            streamingEnabled: true
        )
        try context.validateStreamingOutput()
        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let engine = try await MainActor.run {
            try makeSessionEngine(
                SessionEngineRequest(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools,
                    adapterPath: adapterPath
                )
            )
        }
        let response = try await executeSessionMessage(
            engine: engine,
            request: SessionMessageRequest(
                prompt: resolvedPrompt.value,
                messageIndex: nil,
                generationOptions: generationOptions,
                startedEvent: "started",
                deltaEvent: "delta",
                completedEvent: nil
            ),
            context: context
        )
        let snapshot = await MainActor.run {
            captureSessionSnapshot(engine: engine, includeTranscript: transcriptFlags.transcript)
        }
        try emitStreamResult(
            response: response,
            prompt: resolvedPrompt.value,
            snapshot: snapshot,
            context: context
        )
    }
}

struct SessionChatCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "chat",
        abstract: "Send multiple prompts through one shared session."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var transcriptFlags: TranscriptIncludeFlags
    @OptionGroup var session: SessionOptions
    @OptionGroup var streaming: StreamingOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedMessages = try session.resolveMessages()
        let validatedMessages = resolvedMessages.map(\.value)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try emitDryRun(
                messages: resolvedMessages,
                adapterPath: adapterPath,
                tools: toolResolution,
                output: resolvedOutput
            )
            return
        }

        let context = SessionCommandContext(
            command: "session chat",
            adapterPath: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            output: resolvedOutput,
            verbose: options.verbose,
            streamingEnabled: streaming.stream
        )
        try context.validateStreamingOutput()
        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let engine = try await MainActor.run {
            try makeSessionEngine(
                SessionEngineRequest(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools,
                    adapterPath: adapterPath
                )
            )
        }
        let exchanges = try await executeSessionChat(
            engine: engine,
            request: SessionChatRequest(
                messages: validatedMessages,
                generationOptions: generationOptions
            ),
            context: context
        )
        let snapshot = await MainActor.run {
            captureSessionSnapshot(engine: engine, includeTranscript: transcriptFlags.transcript)
        }
        try emitChatResult(
            messages: validatedMessages,
            exchanges: exchanges,
            snapshot: snapshot,
            context: context
        )
    }
}

private extension SessionStreamCommand {
    func emitDryRun(
        prompt: ResolvedTextInput,
        adapterPath: String?,
        tools: ResolvedToolSet,
        output: CLIOutputOptions
    ) throws {
        try CLIOutput.emit(
            payload: DryRunPayload(
                command: "session stream",
                adapter: adapterPath,
                prompt: prompt.value,
                promptFile: prompt.file,
                useCase: useCaseFlags.useCase.rawValue,
                guardrails: generation.guardrails.afmArgumentValue,
                toolFiles: tools.references.map { $0.filePath },
                toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
            ),
            human: "[dry-run] afm session stream\nPrompt: \(prompt.value)",
            options: output
        )
    }
}

private extension SessionChatCommand {
    func emitDryRun(
        messages: [ResolvedTextInput],
        adapterPath: String?,
        tools: ResolvedToolSet,
        output: CLIOutputOptions
    ) throws {
        try CLIOutput.emit(
            payload: DryRunPayload(
                command: "session chat",
                adapter: adapterPath,
                messages: messages.map(\.value),
                messageFiles: messages.compactMap(\.file),
                useCase: useCaseFlags.useCase.rawValue,
                guardrails: generation.guardrails.afmArgumentValue,
                toolFiles: tools.references.map { $0.filePath },
                toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
            ),
            human: "[dry-run] afm session chat\nMessages: \(messages.count)",
            options: output
        )
    }
}

private func emitRespondResult(
    response: String,
    prompt: String,
    snapshot: SessionSnapshot,
    context: SessionCommandContext
) throws {
    let payload = SessionResponsePayload(
        command: context.command,
        adapter: context.adapterPath,
        useCase: context.useCase,
        guardrails: context.guardrails,
        prompt: prompt,
        messages: nil,
        response: response,
        exchanges: nil,
        sessionCount: snapshot.sessionCount,
        tokenCount: snapshot.tokenCount,
        tokenUsage: snapshot.tokenUsage,
        transcript: snapshot.transcript
    )
    let human = humanReadableSessionResponse(
        response: response,
        snapshot: snapshot,
        verbose: context.verbose
    )
    try CLIOutput.emit(payload: payload, human: human, options: context.output)
}

private func emitStreamResult(
    response: String,
    prompt: String,
    snapshot: SessionSnapshot,
    context: SessionCommandContext
) throws {
    let payload = SessionResponsePayload(
        command: context.command,
        adapter: context.adapterPath,
        useCase: context.useCase,
        guardrails: context.guardrails,
        prompt: prompt,
        messages: nil,
        response: response,
        exchanges: nil,
        sessionCount: snapshot.sessionCount,
        tokenCount: snapshot.tokenCount,
        tokenUsage: snapshot.tokenUsage,
        transcript: snapshot.transcript
    )
    if context.streamsToJSON {
        emitSessionStreamingEvent(
            context.event(
                "completed",
                content: SessionStreamingEventContent(
                    prompt: prompt,
                    response: response,
                    sessionCount: snapshot.sessionCount,
                    tokenCount: snapshot.tokenCount,
                    tokenUsage: snapshot.tokenUsage,
                    transcript: snapshot.transcript
                )
            )
        )
        return
    }

    let humanResponse = context.streamsToConsole ? "" : response
    let human = humanReadableSessionResponse(
        response: humanResponse,
        snapshot: snapshot,
        verbose: context.verbose
    )
    try CLIOutput.emit(payload: payload, human: human, options: context.output)
}

private func emitChatResult(
    messages: [String],
    exchanges: [AFMConversationExchange],
    snapshot: SessionSnapshot,
    context: SessionCommandContext
) throws {
    let payload = SessionResponsePayload(
        command: context.command,
        adapter: context.adapterPath,
        useCase: context.useCase,
        guardrails: context.guardrails,
        prompt: nil,
        messages: messages,
        response: nil,
        exchanges: exchanges,
        sessionCount: snapshot.sessionCount,
        tokenCount: snapshot.tokenCount,
        tokenUsage: snapshot.tokenUsage,
        transcript: snapshot.transcript
    )
    if context.streamsToJSON {
        emitSessionStreamingEvent(
            context.event(
                "session_completed",
                content: SessionStreamingEventContent(
                    exchanges: exchanges,
                    sessionCount: snapshot.sessionCount,
                    tokenCount: snapshot.tokenCount,
                    tokenUsage: snapshot.tokenUsage,
                    transcript: snapshot.transcript
                )
            )
        )
        return
    }

    let human = humanReadableConversation(
        ConversationRenderContext(
            exchanges: exchanges,
            transcript: snapshot.transcript,
            sessionCount: snapshot.sessionCount,
            tokenCount: snapshot.tokenCount,
            tokenUsage: snapshot.tokenUsage,
            verbose: context.verbose,
            streamed: context.streamsToConsole
        )
    )
    try CLIOutput.emit(payload: payload, human: human, options: context.output)
}
