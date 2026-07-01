import ArgumentParser
import Foundation
import FoundationModelsKit
import FoundationModels

struct TranscriptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "transcript",
        abstract: "Export transcript data from a session flow.",
        subcommands: [
            TranscriptExportCommand.self
        ]
    )
}

struct ExportedTranscriptPayload: Encodable {
    struct Entry: Encodable {
        let role: String
        let content: String
    }

    let command: String
    let adapter: String?
    let useCase: String
    let guardrails: String
    let messages: [String]
    let entries: [Entry]
    let sessionCount: Int
    let tokenCount: Int
}

struct TranscriptExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Run a chat flow and write transcript JSON to a file."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var outputFile: ArtifactOutputOptions
    @OptionGroup var session: SessionOptions
    @OptionGroup var toolSource: ToolSourceOptions

    mutating func run() async throws {
        let resolvedMessages = try session.resolveMessages()
        let messages = resolvedMessages.map(\.value)
        let exportPath = try validatedExportPath(outputFile.file)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let toolResolution = try resolveToolManifests(toolSource)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "transcript export",
                    adapter: adapterPath,
                    messages: messages,
                    messageFiles: resolvedMessages.compactMap { $0.file },
                    file: exportPath,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    toolFiles: toolResolution.references.map { $0.filePath },
                    toolDirectory: toolSource.tool.isEmpty ? nil : expandedPathString(toolSource.toolDir)
                ),
                human: "[dry-run] afm transcript export\nFile: \(exportPath)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let engine = try await MainActor.run {
            try makeConversationEngine(
                configuration: defaultConversationConfiguration(
                    systemPrompt: generation.systemPrompt,
                    useCase: useCaseFlags.useCase,
                    guardrails: generation.guardrails,
                    tools: toolResolution.tools
                ),
                adapterPath: adapterPath
            )
        }

        for entry in messages {
            _ = try await engine.sendMessage(entry, generationOptions: generationOptions)
        }

        try await exportTranscript(
            from: engine,
            messages: messages,
            adapterPath: adapterPath,
            exportPath: exportPath,
            outputOptions: resolvedOutput
        )
    }
}

private extension TranscriptExportCommand {
    func exportTranscript(
        from engine: FoundationModelConversationEngine,
        messages: [String],
        adapterPath: String?,
        exportPath: String,
        outputOptions: CLIOutputOptions
    ) async throws {
        let entries = await MainActor.run { transcriptPayload(engine.session.transcript) }
        let sessionCount = await MainActor.run { engine.sessionCount }
        let tokenCount = await MainActor.run { engine.currentTokenCount }
        let payload = ExportedTranscriptPayload(
            command: "transcript export",
            adapter: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            messages: messages,
            entries: entries.map { entry in
                ExportedTranscriptPayload.Entry(role: entry.role, content: entry.content)
            },
            sessionCount: sessionCount,
            tokenCount: tokenCount
        )

        try writeJSONFile(payload, to: exportPath)
        let human = """
        Transcript exported
        File: \(exportPath)
        Entries: \(entries.count)
        """
        let verboseHuman: String
        if options.verbose {
            verboseHuman = """
            \(human)
            Sessions: \(sessionCount)
            Token count: \(tokenCount)
            """
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: outputOptions)
    }
}

struct FeedbackCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "feedback",
        abstract: "Export Foundation Models feedback attachments.",
        subcommands: [
            FeedbackExportCommand.self
        ]
    )
}

struct FeedbackExportSummaryPayload: Encodable {
    let command: String
    let adapter: String?
    let useCase: String
    let guardrails: String
    let prompt: String
    let sentiment: String?
    let issues: [String]
    let file: String
    let bytes: Int
}

struct FeedbackExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Run one prompt and export a Feedback Assistant attachment."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var issueFlags: FeedbackIssueFlags
    @OptionGroup var outputFile: ArtifactOutputOptions
    @OptionGroup var promptInput: PromptInputOptions

    @Option(name: .long, help: "Optional feedback sentiment.")
    var sentiment: CLIFeedbackSentiment?

    @Option(name: .customLong("desired-output"), help: "Optional desired output to include with the feedback.")
    var desiredOutput: String?

    mutating func run() async throws {
        let resolvedPrompt = try requiredResolvedInput(promptInput.resolve())
        let exportPath = try validatedExportPath(outputFile.file)
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let issues = try issueFlags.resolvedIssues()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "feedback export",
                    adapter: adapterPath,
                    prompt: resolvedPrompt.value,
                    promptFile: resolvedPrompt.file,
                    file: exportPath,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    feedbackIssues: issueFlags.issue.map(\.rawValue)
                ),
                human: "[dry-run] afm feedback export\nFile: \(exportPath)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let model = try FoundationModelsModelFactory.makeModel(
            useCase: useCaseFlags.useCase,
            guardrails: generation.guardrails,
            adapterURL: adapterURL(from: adapterPath)
        )
        let session = makeFeedbackSession(model: model, systemPrompt: generation.systemPrompt)
        if let generationOptions {
            _ = try await session.respond(to: resolvedPrompt.value, options: generationOptions.foundationModelsValue)
        } else {
            _ = try await session.respond(to: resolvedPrompt.value)
        }

        let data = session.logFeedbackAttachment(
            sentiment: sentiment?.foundationModelsValue,
            issues: issues,
            desiredOutput: desiredFeedbackEntry()
        )
        try writeFileData(data, to: exportPath)
        try emitFeedbackExport(
            data: data,
            resolvedPrompt: resolvedPrompt,
            adapterPath: adapterPath,
            exportPath: exportPath,
            outputOptions: resolvedOutput
        )
    }
}

private extension FeedbackExportCommand {
    func desiredFeedbackEntry() -> Transcript.Entry? {
        guard let desiredOutput,
              !desiredOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return Transcript.Entry.response(
            Transcript.Response(
                assetIDs: [],
                segments: [.text(.init(content: desiredOutput))]
            )
        )
    }

    func emitFeedbackExport(
        data: Data,
        resolvedPrompt: ResolvedTextInput,
        adapterPath: String?,
        exportPath: String,
        outputOptions: CLIOutputOptions
    ) throws {
        let payload = FeedbackExportSummaryPayload(
            command: "feedback export",
            adapter: adapterPath,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            prompt: resolvedPrompt.value,
            sentiment: sentiment?.rawValue,
            issues: issueFlags.issue.map(\.rawValue),
            file: exportPath,
            bytes: data.count
        )
        let human = """
        Feedback exported
        File: \(exportPath)
        Bytes: \(data.count)
        """
        let verboseHuman: String
        if options.verbose {
            let sentimentValue = sentiment?.rawValue ?? "unspecified"
            verboseHuman = """
            \(human)
            Sentiment: \(sentimentValue)
            """
        } else {
            verboseHuman = human
        }
        try CLIOutput.emit(payload: payload, human: verboseHuman, options: outputOptions)
    }
}

private func makeFeedbackSession(model: SystemLanguageModel, systemPrompt: String?) -> LanguageModelSession {
    let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
    if let trimmedSystemPrompt, !trimmedSystemPrompt.isEmpty {
        return LanguageModelSession(model: model, instructions: trimmedSystemPrompt)
    }
    return LanguageModelSession(model: model)
}

private func writeJSONFile<Payload: Encodable>(_ payload: Payload, to path: String) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let data = try encoder.encode(payload)
    try writeFileData(data, to: path)
}

private func writeFileData(_ data: Data, to path: String) throws {
    let url = try preparedOutputURL(for: path)

    do {
        try data.write(to: url, options: .atomic)
    } catch {
        throw AFMRuntimeError.fileWriteFailed(error.localizedDescription)
    }
}

private func preparedOutputURL(for path: String) throws -> URL {
    let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedPath.isEmpty else {
        throw AFMRuntimeError.invalidRequest("Missing export file path")
    }

    let url = URL(fileURLWithPath: trimmedPath)
    let directoryURL = url.deletingLastPathComponent()

    do {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    } catch {
        throw AFMRuntimeError.fileWriteFailed(error.localizedDescription)
    }

    return url
}
