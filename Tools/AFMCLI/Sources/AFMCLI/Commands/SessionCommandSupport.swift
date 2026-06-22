import ArgumentParser
import Foundation
import FoundationLabCore
import FoundationModels
import FoundationModelsKit

struct SessionStreamingEventPayload: Encodable {
    let event: String
    let command: String
    let adapter: String?
    let useCase: String?
    let guardrails: String?
    let messageIndex: Int?
    let prompt: String?
    let content: String?
    let response: String?
    let exchanges: [AFMConversationExchange]?
    let sessionCount: Int?
    let tokenCount: Int?
    let tokenUsage: ModelTokenUsage?
    let transcript: [CLITranscriptEntry]?
}

struct SessionStreamingEventContent {
    var messageIndex: Int?
    var prompt: String?
    var content: String?
    var response: String?
    var exchanges: [AFMConversationExchange]?
    var sessionCount: Int?
    var tokenCount: Int?
    var tokenUsage: ModelTokenUsage?
    var transcript: [CLITranscriptEntry]?
}

struct SessionCommandContext {
    let command: String
    let adapterPath: String?
    let useCase: String
    let guardrails: String
    let output: CLIOutputOptions
    let verbose: Bool
    let streamingEnabled: Bool

    var streamsToConsole: Bool {
        streamingEnabled && output.format == .text
    }

    var streamsToJSON: Bool {
        streamingEnabled && output.format == .json
    }

    func validateStreamingOutput() throws {
        if streamsToJSON && output.pretty {
            throw ValidationError("--pretty is not supported with streaming JSON output")
        }
    }

    func event(
        _ name: String,
        content: SessionStreamingEventContent = SessionStreamingEventContent()
    ) -> SessionStreamingEventPayload {
        SessionStreamingEventPayload(
            event: name,
            command: command,
            adapter: adapterPath,
            useCase: useCase,
            guardrails: guardrails,
            messageIndex: content.messageIndex,
            prompt: content.prompt,
            content: content.content,
            response: content.response,
            exchanges: content.exchanges,
            sessionCount: content.sessionCount,
            tokenCount: content.tokenCount,
            tokenUsage: content.tokenUsage,
            transcript: content.transcript
        )
    }
}

struct SessionEngineRequest {
    let systemPrompt: String?
    let useCase: FoundationLabModelUseCase
    let guardrails: FoundationLabGuardrails
    let tools: [any Tool]
    let adapterPath: String?
}

struct SessionMessageRequest {
    let prompt: String
    let messageIndex: Int?
    let generationOptions: FoundationLabGenerationOptions?
    let startedEvent: String?
    let deltaEvent: String?
    let completedEvent: String?
}

struct SessionChatRequest {
    let messages: [String]
    let generationOptions: FoundationLabGenerationOptions?
}

struct SessionSnapshot {
    let transcript: [CLITranscriptEntry]?
    let sessionCount: Int
    let tokenCount: Int
    let tokenUsage: ModelTokenUsage?
}

struct ConversationRenderContext {
    let exchanges: [AFMConversationExchange]
    let transcript: [CLITranscriptEntry]?
    let sessionCount: Int
    let tokenCount: Int
    let tokenUsage: ModelTokenUsage?
    let verbose: Bool
    let streamed: Bool
}

@MainActor
func makeSessionEngine(_ request: SessionEngineRequest) throws -> FoundationLabConversationEngine {
    try makeConversationEngine(
        configuration: defaultConversationConfiguration(
            systemPrompt: request.systemPrompt,
            useCase: request.useCase,
            guardrails: request.guardrails,
            tools: request.tools
        ),
        adapterPath: request.adapterPath
    )
}

@MainActor
func executeSessionMessage(
    engine: FoundationLabConversationEngine,
    request: SessionMessageRequest,
    context: SessionCommandContext
) async throws -> String {
    beginStreamingMessage(request, context: context)

    let response: String
    if context.streamingEnabled {
        var latestPrinted = ""
        response = try await engine.sendStreamingMessage(
            request.prompt,
            generationOptions: request.generationOptions
        ) { partial in
            emitSessionPartial(
                partial,
                latestPrinted: &latestPrinted,
                request: request,
                context: context
            )
        }
    } else {
        response = try await engine.sendMessage(
            request.prompt,
            generationOptions: request.generationOptions
        )
    }

    finishStreamingMessage(response, request: request, context: context)
    return response
}

@MainActor
func executeSessionChat(
    engine: FoundationLabConversationEngine,
    request: SessionChatRequest,
    context: SessionCommandContext
) async throws -> [AFMConversationExchange] {
    var exchanges: [AFMConversationExchange] = []
    for (index, prompt) in request.messages.enumerated() {
        let response = try await executeSessionMessage(
            engine: engine,
            request: SessionMessageRequest(
                prompt: prompt,
                messageIndex: index,
                generationOptions: request.generationOptions,
                startedEvent: "message_started",
                deltaEvent: "message_delta",
                completedEvent: "message_completed"
            ),
            context: context
        )
        exchanges.append(AFMConversationExchange(prompt: prompt, response: response, isError: false))
    }
    return exchanges
}

@MainActor
func captureSessionSnapshot(
    engine: FoundationLabConversationEngine,
    includeTranscript: Bool
) -> SessionSnapshot {
    SessionSnapshot(
        transcript: includeTranscript ? transcriptPayload(engine.session.transcript) : nil,
        sessionCount: engine.sessionCount,
        tokenCount: engine.currentTokenCount,
        tokenUsage: engine.currentTokenUsage
    )
}

func humanReadableSessionResponse(
    response: String,
    snapshot: SessionSnapshot,
    verbose: Bool
) -> String {
    var lines: [String] = []
    if !response.isEmpty {
        lines.append(response)
    }
    if let transcript = snapshot.transcript, !transcript.isEmpty {
        if !lines.isEmpty { lines.append("") }
        lines.append("Transcript")
        lines.append(
            transcript.map { "\($0.role.capitalized): \($0.content)" }.joined(separator: "\n\n")
        )
    }
    if verbose {
        if !lines.isEmpty { lines.append("") }
        lines.append("Sessions: \(snapshot.sessionCount)")
        appendTokenAccounting(
            tokenCount: snapshot.tokenCount,
            tokenUsage: snapshot.tokenUsage,
            to: &lines
        )
    }
    return lines.joined(separator: "\n")
}

func emitSessionStreamingEvent(_ payload: SessionStreamingEventPayload) {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]

    guard let data = try? encoder.encode(payload),
          let text = String(data: data, encoding: .utf8) else {
        return
    }

    print(text)
    fflush(stdout)
}

private func beginStreamingMessage(
    _ request: SessionMessageRequest,
    context: SessionCommandContext
) {
    if context.streamsToConsole {
        if request.messageIndex != nil {
            print("User: \(request.prompt)")
        }
        print("Assistant: ", terminator: "")
        fflush(stdout)
    }

    if context.streamsToJSON, let event = request.startedEvent {
        emitSessionStreamingEvent(
            context.event(
                event,
                content: SessionStreamingEventContent(
                    messageIndex: request.messageIndex,
                    prompt: request.prompt
                )
            )
        )
    }
}

private func emitSessionPartial(
    _ partial: String,
    latestPrinted: inout String,
    request: SessionMessageRequest,
    context: SessionCommandContext
) {
    if context.streamsToConsole {
        printStreamingText(partial, after: latestPrinted)
        latestPrinted = partial
        return
    }

    if context.streamsToJSON, let event = request.deltaEvent {
        emitSessionStreamingEvent(
            context.event(
                event,
                content: SessionStreamingEventContent(
                    messageIndex: request.messageIndex,
                    prompt: request.prompt,
                    content: partial
                )
            )
        )
    }
}

private func printStreamingText(_ partial: String, after latestPrinted: String) {
    if partial.hasPrefix(latestPrinted) {
        let suffix = String(partial.dropFirst(latestPrinted.count))
        guard !suffix.isEmpty else { return }
        print(suffix, terminator: "")
    } else {
        print(partial, terminator: "")
    }
    fflush(stdout)
}

private func finishStreamingMessage(
    _ response: String,
    request: SessionMessageRequest,
    context: SessionCommandContext
) {
    if context.streamsToConsole {
        print("")
    }

    if context.streamsToJSON, let event = request.completedEvent {
        emitSessionStreamingEvent(
            context.event(
                event,
                content: SessionStreamingEventContent(
                    messageIndex: request.messageIndex,
                    prompt: request.prompt,
                    response: response
                )
            )
        )
    }
}

func humanReadableConversation(_ context: ConversationRenderContext) -> String {
    var lines: [String] = []
    if !context.streamed {
        for exchange in context.exchanges {
            lines.append("User: \(exchange.prompt)")
            lines.append("Assistant: \(exchange.response)")
            lines.append("")
        }
        if !lines.isEmpty {
            _ = lines.popLast()
        }
    }
    if let transcript = context.transcript, !transcript.isEmpty {
        if !lines.isEmpty { lines.append("") }
        lines.append("Transcript")
        lines.append(
            transcript.map { "\($0.role.capitalized): \($0.content)" }.joined(separator: "\n\n")
        )
    }
    if context.verbose {
        if !lines.isEmpty { lines.append("") }
        lines.append("Sessions: \(context.sessionCount)")
        appendTokenAccounting(
            tokenCount: context.tokenCount,
            tokenUsage: context.tokenUsage,
            to: &lines
        )
    }
    return lines.joined(separator: "\n")
}

private func appendTokenAccounting(
    tokenCount: Int,
    tokenUsage: ModelTokenUsage?,
    to lines: inout [String]
) {
    lines.append("Context token count: \(tokenCount)")
    guard let tokenUsage else { return }

    lines.append("Input tokens: \(tokenUsage.input.totalTokenCount)")
    if let cachedTokenCount = tokenUsage.input.cachedTokenCount {
        lines.append("Cached input tokens: \(cachedTokenCount)")
    }
    if let output = tokenUsage.output {
        lines.append("Output tokens: \(output.totalTokenCount)")
        if let reasoningTokenCount = output.reasoningTokenCount {
            lines.append("Reasoning output tokens: \(reasoningTokenCount)")
        }
    }
    lines.append("Accounted tokens: \(tokenUsage.totalTokenCount)")
    lines.append("Measurement: \(tokenUsage.measurement.rawValue) (\(tokenUsage.scope.rawValue))")
}

struct ResolvedToolSet {
    let references: [ResolvedArtifactReference]
    let tools: [any Tool]
}

func resolveToolManifests(_ toolSource: ToolSourceOptions) throws -> ResolvedToolSet {
    let references = try toolSource.resolveTools()
    if references.isEmpty {
        return ResolvedToolSet(references: [], tools: [])
    }

    let manifests = try AFMArtifactRegistry.loadTools(from: references)
    return ResolvedToolSet(
        references: references,
        tools: manifests.map { $0 as any Tool }
    )
}

func requiredResolvedInput(_ input: ResolvedTextInput?) throws -> ResolvedTextInput {
    guard let input else {
        throw ValidationError("Please provide --prompt, --prompt-file, or stdin.")
    }
    return input
}
