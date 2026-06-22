import ArgumentParser
import Foundation
import FoundationModels
import FoundationModelsKit

struct TokenCountCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "token-count",
        abstract: "Count tokens in prompts, instructions, schemas, and tool definitions.",
        discussion: """
        Uses Apple's tokenizer on macOS 26.4 and later. On earlier systems, or
        when tokenization is unavailable, the result is explicitly marked as
        estimated. This command counts supplied context; generation usage can
        be larger because the runtime adds model and session framing.
        """
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var toolSource: ToolSourceOptions
    @OptionGroup var schemaSource: SchemaSourceOptions

    @Argument(help: "Prompt to count. Prefix with @ to read from a file.")
    var positionalPrompt: String?

    @Option(name: .long, help: "Prompt to count. Prefix with @ to read from a file.")
    var prompt: String?

    @Option(name: .customLong("prompt-file"), help: "Read the prompt from a file path.")
    var promptFile: String?

    @Option(name: .shortAndLong, help: "Instructions to include. Prefix with @ to read from a file.")
    var instructions: String?

    @Option(name: .customLong("instructions-file"), help: "Read instructions from a file path.")
    var instructionsFile: String?

    @Option(name: .long, help: "Additional prompt text. Repeat to add multiple segments.")
    var text: [String] = []

    @Flag(name: .long, help: "Read the primary prompt from standard input.")
    var stdin = false

    @Flag(name: .shortAndLong, help: "Print only the integer token count.")
    var quiet = false

    @Flag(name: .long, help: "Show per-component counts and estimator comparison.")
    var breakdown = false

    mutating func run() async throws {
        try validateOutputOptions()
        let output = try options.resolvedOutput()
        let input = try resolveInput()
        let artifacts = try resolveArtifacts()

        if options.dryRun {
            try emitDryRun(input: input, artifacts: artifacts, output: output)
            return
        }

        let report = await measure(input: input, artifacts: artifacts)
        if quiet {
            print(report.usage.totalTokenCount)
            return
        }

        try CLIOutput.emit(
            payload: report,
            human: report.humanDescription(detailed: breakdown || options.verbose),
            options: output
        )
    }
}

struct TokenCountReport: Encodable {
    let command: String
    let usage: ModelTokenUsage
    let components: [TokenCountComponent]
    let componentTokenCount: Int
    let calibratedEstimate: Int
    let conservativeEstimate: Int
    let context: TokenCountContext

    func humanDescription(detailed: Bool) -> String {
        var lines = [
            "Token count: \(usage.totalTokenCount)",
            "Measurement: \(usage.measurement.rawValue)"
        ]
        guard detailed else {
            return lines.joined(separator: "\n")
        }

        lines.append("Context: \(context.usedTokenCount) / \(context.limitTokenCount) (\(context.formattedPercentage))")
        lines.append("Remaining: \(context.remainingTokenCount)")
        lines.append("")
        lines.append("Breakdown")
        lines.append(contentsOf: components.map { component in
            "  \(component.label): \(component.tokenCount) [\(component.measurement.rawValue)]"
        })
        lines.append("")
        lines.append("Calibrated estimate: \(calibratedEstimate)")
        lines.append("Conservative estimate: \(conservativeEstimate)")
        return lines.joined(separator: "\n")
    }
}

struct TokenCountComponent: Encodable {
    enum Kind: String, Encodable {
        case instructions
        case prompt
        case schema
        case tools
    }

    let kind: Kind
    let label: String
    let tokenCount: Int
    let measurement: ModelTokenUsage.Measurement
    let characterCount: Int
    let itemCount: Int
    let files: [String]?
}

struct TokenCountContext: Encodable {
    let usedTokenCount: Int
    let limitTokenCount: Int
    let remainingTokenCount: Int
    let percentageUsed: Double
    let exceedsLimit: Bool

    var formattedPercentage: String {
        String(format: "%.1f%%", percentageUsed)
    }
}

private struct ResolvedTokenCountInput {
    let instructions: ResolvedTextInput?
    let promptSegments: [ResolvedTextInput]
}

private struct ResolvedTokenCountArtifacts {
    let schema: ResolvedTokenCountSchema?
    let tools: ResolvedToolSet
    let toolSourceText: String
}

private struct ResolvedTokenCountSchema {
    let reference: ResolvedArtifactReference
    let schema: GenerationSchema
    let sourceText: String
}

private struct MeasuredTokenCountComponent {
    let component: TokenCountComponent
    let fallbackText: String
}

private extension TokenCountCommand {
    func validateOutputOptions() throws {
        if quiet && (breakdown || options.verbose || options.pretty || options.dryRun) {
            throw ValidationError("--quiet cannot be combined with --breakdown, --verbose, --pretty, or --dry-run.")
        }
    }

    func resolveInput() throws -> ResolvedTokenCountInput {
        let resolvedInstructions = try resolveOptionalText(
            inline: instructions,
            file: instructionsFile,
            inlineName: "--instructions",
            fileName: "--instructions-file"
        )
        let primaryPrompt = try resolvePrimaryPrompt()
        var promptSegments = primaryPrompt.map { [$0] } ?? []
        promptSegments.append(contentsOf: try text.map {
            try resolveInlineValue($0, optionName: "--text")
        })

        let hasArtifacts = schemaSource.schema != nil || !toolSource.tool.isEmpty
        guard resolvedInstructions != nil || !promptSegments.isEmpty || hasArtifacts else {
            throw ValidationError(
                "Provide a prompt, --instructions, --text, --schema, --tool, or stdin."
            )
        }
        return ResolvedTokenCountInput(
            instructions: resolvedInstructions,
            promptSegments: promptSegments
        )
    }

    func resolvePrimaryPrompt() throws -> ResolvedTextInput? {
        let explicitValues = [positionalPrompt, prompt, promptFile].compactMap { $0 }
        let explicitCount = explicitValues.count + (stdin ? 1 : 0)
        guard explicitCount <= 1 else {
            throw ValidationError("Use only one positional prompt, --prompt, --prompt-file, or --stdin.")
        }

        if let positionalPrompt {
            return try resolveInlineValue(positionalPrompt, optionName: "prompt")
        }
        if let prompt {
            return try resolveInlineValue(prompt, optionName: "--prompt")
        }
        if let promptFile {
            return try readFileInput(path: promptFile, optionName: "--prompt-file")
        }
        if stdin {
            return try readStandardInput(
                optionName: "--stdin",
                requiredMessage: "Please provide a non-empty prompt on stdin."
            )
        }
        if shouldAutomaticallyReadFromStdin() {
            return try readOptionalStandardInput(optionName: "stdin")
        }
        return nil
    }

    func resolveOptionalText(
        inline: String?,
        file: String?,
        inlineName: String,
        fileName: String
    ) throws -> ResolvedTextInput? {
        guard inline == nil || file == nil else {
            throw ValidationError("Use only one of \(inlineName) or \(fileName).")
        }
        if let inline {
            return try resolveInlineValue(inline, optionName: inlineName)
        }
        if let file {
            return try readFileInput(path: file, optionName: fileName)
        }
        return nil
    }

    func resolveArtifacts() throws -> ResolvedTokenCountArtifacts {
        let tools = try resolveToolManifests(toolSource)
        let toolSourceText = try tools.references.map {
            try String(contentsOfFile: $0.filePath, encoding: .utf8)
        }
        .joined(separator: "\n")
        let schema: ResolvedTokenCountSchema?
        if schemaSource.schema != nil {
            let reference = try schemaSource.resolve()
            let document = try AFMArtifactRegistry.loadSchemaDocument(from: reference)
            let sourceText = try String(contentsOfFile: reference.filePath, encoding: .utf8)
            schema = ResolvedTokenCountSchema(
                reference: reference,
                schema: try document.generationSchema(
                    rootName: reference.identifier.camelizedSchemaName()
                ),
                sourceText: sourceText
            )
        } else {
            schema = nil
        }
        return ResolvedTokenCountArtifacts(
            schema: schema,
            tools: tools,
            toolSourceText: toolSourceText
        )
    }

    func measure(
        input: ResolvedTokenCountInput,
        artifacts: ResolvedTokenCountArtifacts
    ) async -> TokenCountReport {
        let model = SystemLanguageModel.default
        let measurements = await [
            measureInstructions(input.instructions, model: model),
            measurePrompt(input.promptSegments, model: model),
            measureSchema(artifacts.schema, model: model),
            measureTools(artifacts, model: model)
        ].compactMap { $0 }

        return makeReport(
            model: model,
            components: measurements.map(\.component),
            fallbackTexts: measurements.map(\.fallbackText)
        )
    }

    func component(
        kind: TokenCountComponent.Kind,
        usage: ModelTokenUsage,
        text: String,
        itemCount: Int,
        files: [String]?
    ) -> TokenCountComponent {
        TokenCountComponent(
            kind: kind,
            label: componentLabel(kind: kind, itemCount: itemCount),
            tokenCount: usage.totalTokenCount,
            measurement: usage.measurement,
            characterCount: text.count,
            itemCount: itemCount,
            files: files
        )
    }

    func componentLabel(kind: TokenCountComponent.Kind, itemCount: Int) -> String {
        switch kind {
        case .instructions:
            "Instructions"
        case .prompt:
            itemCount == 1 ? "Prompt" : "Prompt (\(itemCount) segments)"
        case .schema:
            "Schema"
        case .tools:
            itemCount == 1 ? "Tool definitions" : "Tool definitions (\(itemCount))"
        }
    }

    func measureInstructions(
        _ instructions: ResolvedTextInput?,
        model: SystemLanguageModel
    ) async -> MeasuredTokenCountComponent? {
        guard let instructions else { return nil }
        let usage = await model.tokenUsage(
            for: Instructions(instructions.value),
            estimatedFrom: instructions.value
        )
        return MeasuredTokenCountComponent(
            component: component(
                kind: .instructions,
                usage: usage,
                text: instructions.value,
                itemCount: 1,
                files: instructions.file.map { [$0] }
            ),
            fallbackText: instructions.value
        )
    }

    func measurePrompt(
        _ segments: [ResolvedTextInput],
        model: SystemLanguageModel
    ) async -> MeasuredTokenCountComponent? {
        guard !segments.isEmpty else { return nil }
        let values = segments.map(\.value)
        let fallbackText = values.joined(separator: "\n")
        let prompt = Prompt {
            for value in values {
                value
            }
        }
        let usage = await model.tokenUsage(for: prompt, estimatedFrom: fallbackText)
        return MeasuredTokenCountComponent(
            component: component(
                kind: .prompt,
                usage: usage,
                text: fallbackText,
                itemCount: values.count,
                files: segments.compactMap(\.file).nonEmpty
            ),
            fallbackText: fallbackText
        )
    }

    func measureSchema(
        _ schema: ResolvedTokenCountSchema?,
        model: SystemLanguageModel
    ) async -> MeasuredTokenCountComponent? {
        guard let schema else { return nil }
        let usage = await model.tokenUsage(
            for: schema.schema,
            estimatedFrom: schema.sourceText
        )
        return MeasuredTokenCountComponent(
            component: component(
                kind: .schema,
                usage: usage,
                text: schema.sourceText,
                itemCount: 1,
                files: [schema.reference.filePath]
            ),
            fallbackText: schema.sourceText
        )
    }

    func measureTools(
        _ artifacts: ResolvedTokenCountArtifacts,
        model: SystemLanguageModel
    ) async -> MeasuredTokenCountComponent? {
        guard !artifacts.tools.tools.isEmpty else { return nil }
        let usage = await model.tokenUsage(
            for: artifacts.tools.tools,
            estimatedFrom: artifacts.toolSourceText
        )
        return MeasuredTokenCountComponent(
            component: component(
                kind: .tools,
                usage: usage,
                text: artifacts.toolSourceText,
                itemCount: artifacts.tools.tools.count,
                files: artifacts.tools.references.map(\.filePath)
            ),
            fallbackText: artifacts.toolSourceText
        )
    }

    func makeReport(
        model: SystemLanguageModel,
        components: [TokenCountComponent],
        fallbackTexts: [String]
    ) -> TokenCountReport {
        let componentTotal = components.reduce(0) { $0 + $1.tokenCount }
        let measurement: ModelTokenUsage.Measurement = components.allSatisfy {
            $0.measurement == .tokenized
        } ? .tokenized : .estimated
        let limit = model.contextSize
        let percentage = limit > 0 ? Double(componentTotal) / Double(limit) * 100 : 0
        let calibratedEstimate = fallbackTexts.reduce(0) { $0 + estimateTokens(from: $1) }
        let conservativeEstimate = fallbackTexts.reduce(0) {
            $0 + estimateTokensConservative(from: $1)
        }

        return TokenCountReport(
            command: "token-count",
            usage: ModelTokenUsage(
                inputTokenCount: componentTotal,
                measurement: measurement
            ),
            components: components,
            componentTokenCount: componentTotal,
            calibratedEstimate: calibratedEstimate,
            conservativeEstimate: conservativeEstimate,
            context: TokenCountContext(
                usedTokenCount: componentTotal,
                limitTokenCount: limit,
                remainingTokenCount: max(0, limit - componentTotal),
                percentageUsed: percentage,
                exceedsLimit: componentTotal > limit
            )
        )
    }

    func emitDryRun(
        input: ResolvedTokenCountInput,
        artifacts: ResolvedTokenCountArtifacts,
        output: CLIOutputOptions
    ) throws {
        let payload = TokenCountDryRunPayload(
            status: "dry_run",
            command: "token-count",
            instructions: input.instructions?.value,
            promptSegments: input.promptSegments.map(\.value),
            schemaFile: artifacts.schema?.reference.filePath,
            toolFiles: artifacts.tools.references.map(\.filePath)
        )
        try CLIOutput.emit(
            payload: payload,
            human: "[dry-run] afm token-count",
            options: output
        )
    }
}

private struct TokenCountDryRunPayload: Encodable {
    let status: String
    let command: String
    let instructions: String?
    let promptSegments: [String]
    let schemaFile: String?
    let toolFiles: [String]
}

private extension Array {
    var nonEmpty: Self? {
        isEmpty ? nil : self
    }
}
