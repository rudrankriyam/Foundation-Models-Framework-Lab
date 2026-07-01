import ArgumentParser
import Foundation
import FoundationModelsKit
import FoundationModels

struct SchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "schema",
        abstract: "Run typed and dynamic schema workflows.",
        discussion: HelpText.schema,
        subcommands: [
            SchemaObjectCommand.self,
            SchemaListCommand.self,
            SchemaRunCommand.self
        ]
    )
}

struct SchemaListPayload: Encodable {
    let schemas: [AFMSchemaExampleDescriptor]
}

struct SchemaListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "Show available typed and dynamic schema workflows."
    )

    @OptionGroup var options: GlobalCommandOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(command: "schema list"),
                human: "[dry-run] afm schema list",
                options: resolvedOutput
            )
            return
        }
        let payload = SchemaListPayload(schemas: AFMSchemaCatalog.examples)
        var lines = AFMSchemaCatalog.examples.map { example in
            let presetNames = example.presets.map(\.id).joined(separator: ", ")
            return "\(example.id): \(example.title)\n  \(example.summary)\n  Presets: \(presetNames)"
        }
        if options.verbose {
            lines.append("Schema count: \(AFMSchemaCatalog.examples.count)")
        }
        let human = lines.joined(separator: "\n\n")

        try CLIOutput.emit(payload: payload, human: human, options: resolvedOutput)
    }
}

struct SchemaRunCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "run",
        abstract: "Execute one schema workflow.",
        subcommands: [
            SchemaCustomCommand.self,
            TypedPersonSchemaCommand.self,
            BasicObjectSchemaCommand.self,
            ArraySchemaCommand.self,
            EnumSchemaCommand.self
        ]
    )
}

struct TypedSchemaPayload<Output: Encodable>: Encodable {
    let command: String
    let adapter: String?
    let preset: String
    let useCase: String
    let guardrails: String
    let includeSchemaInPrompt: Bool
    let input: String
    let output: Output
    let tokenCount: Int?
}

struct DynamicSchemaPayload: Encodable {
    let command: String
    let adapter: String?
    let preset: String
    let useCase: String
    let guardrails: String
    let includeSchemaInPrompt: Bool
    let input: String
    let json: String
    let tokenCount: Int?
    let schemaFile: String?
}

struct SchemaCustomCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "custom",
        abstract: "Run a dynamic schema loaded from a JSON or YAML file."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions
    @OptionGroup var schemaSource: SchemaSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        let schemaReference = try schemaSource.resolve()
        let schemaDocument = try AFMArtifactRegistry.loadSchemaDocument(from: schemaReference)
        let generationSchema = try schemaDocument.generationSchema(
            fallbackName: schemaReference.identifier.camelizedSchemaName()
        )
        let resolvedInput = try inputSource.resolve()

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "schema run custom",
                    adapter: adapterPath,
                    input: resolvedInput.value,
                    inputFile: resolvedInput.file,
                    schema: schemaReference.identifier,
                    schemaFile: schemaReference.filePath,
                    schemaDirectory: schemaReference.directory,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
                ),
                human: "[dry-run] afm schema run custom\nSchema: \(schemaReference.filePath)\nInput: \(resolvedInput.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let result = try await FoundationModelDynamicSchemaGenerationUseCase().execute(
            FoundationModelDynamicSchemaGenerationRequest(
                prompt: resolvedInput.value,
                schema: generationSchema,
                systemPrompt: generation.systemPrompt,
                modelUseCase: useCaseFlags.useCase,
                guardrails: generation.guardrails,
                adapterURL: adapterURL(from: adapterPath),
                generationOptions: generationOptions,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
                context: afmContext()
            )
        )
        try emitResult(
            result,
            schemaReference: schemaReference,
            resolvedInput: resolvedInput,
            adapterPath: adapterPath,
            outputOptions: resolvedOutput
        )
    }
}

struct TypedPersonSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "typed-person",
        abstract: "Run a typed @Generable person workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    mutating func run() async throws {
        let resolvedOutput = try options.resolvedOutput()
        let generationOptions = try generation.validatedOptions()
        let adapterPath = try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails)
        guard let example = AFMSchemaCatalog.example(id: "typed-person"),
              let preset = example.presets.first else {
            throw AFMRuntimeError.invalidRequest("Missing typed-person schema preset")
        }
        let resolvedInput = try inputSource.resolve(defaultValue: preset.defaultInput)

        if options.dryRun {
            try CLIOutput.emit(
                payload: DryRunPayload(
                    command: "schema run typed-person",
                    adapter: adapterPath,
                    input: resolvedInput.value,
                    inputFile: resolvedInput.file,
                    useCase: useCaseFlags.useCase.rawValue,
                    guardrails: generation.guardrails.afmArgumentValue,
                    includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
                ),
                human: "[dry-run] afm schema run typed-person\nInput: \(resolvedInput.value)",
                options: resolvedOutput
            )
            return
        }

        _ = try requireFoundationModelsAvailability(
            useCase: useCaseFlags.useCase,
            adapterPath: adapterPath
        )
        let result = try await FoundationModelStructuredGenerationUseCase<AFMGeneratedPerson>().execute(
            FoundationModelStructuredGenerationRequest(
                prompt: resolvedInput.value,
                systemPrompt: generation.systemPrompt,
                modelUseCase: useCaseFlags.useCase,
                guardrails: generation.guardrails,
                adapterURL: adapterURL(from: adapterPath),
                generationOptions: generationOptions,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
                context: afmContext()
            )
        )
        try emitResult(
            result,
            preset: preset,
            resolvedInput: resolvedInput,
            adapterPath: adapterPath,
            outputOptions: resolvedOutput
        )
    }
}

private extension SchemaCustomCommand {
    func emitResult(
        _ result: FoundationModelDynamicSchemaGenerationResult,
        schemaReference: ResolvedArtifactReference,
        resolvedInput: ResolvedTextInput,
        adapterPath: String?,
        outputOptions: CLIOutputOptions
    ) throws {
        let json = result.output.jsonString
        let payload = DynamicSchemaPayload(
            command: "schema run custom",
            adapter: adapterPath,
            preset: schemaReference.identifier,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
            input: resolvedInput.value,
            json: json,
            tokenCount: result.metadata.tokenCount,
            schemaFile: schemaReference.filePath
        )
        let human = """
        Custom Schema

        Schema: \(schemaReference.filePath)
        \(json)
        """
        let renderedHuman = verboseHumanOutput(
            human,
            tokenCount: result.metadata.tokenCount,
            verbose: options.verbose
        )
        try CLIOutput.emit(payload: payload, human: renderedHuman, options: outputOptions)
    }
}

private extension TypedPersonSchemaCommand {
    func emitResult(
        _ result: FoundationModelStructuredGenerationResult<AFMGeneratedPerson>,
        preset: AFMSchemaPreset,
        resolvedInput: ResolvedTextInput,
        adapterPath: String?,
        outputOptions: CLIOutputOptions
    ) throws {
        let payload = TypedSchemaPayload(
            command: "schema run typed-person",
            adapter: adapterPath,
            preset: preset.id,
            useCase: useCaseFlags.useCase.rawValue,
            guardrails: generation.guardrails.afmArgumentValue,
            includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt,
            input: resolvedInput.value,
            output: result.output,
            tokenCount: result.metadata.tokenCount
        )
        let human = """
        Typed Person

        Name: \(result.output.name)
        Age: \(result.output.age)
        Occupation: \(result.output.occupation)
        """
        let renderedHuman = verboseHumanOutput(
            human,
            tokenCount: result.metadata.tokenCount,
            verbose: options.verbose
        )
        try CLIOutput.emit(payload: payload, human: renderedHuman, options: outputOptions)
    }
}

private func verboseHumanOutput(
    _ human: String,
    tokenCount: Int?,
    verbose: Bool
) -> String {
    guard verbose, let tokenCount else {
        return human
    }
    return "\(human)\n\nToken count: \(tokenCount)"
}

struct BasicObjectSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "basic-object",
        abstract: "Run a runtime-defined basic object schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "person"

    mutating func run() async throws {
        try await runDynamicSchemaCommand(
            DynamicSchemaCommandRequest(
                command: "schema run basic-object",
                exampleID: "basic-object",
                presetID: preset,
                inputSource: inputSource,
                schemaBuilder: makeBasicObjectSchema,
                options: options,
                generation: generation,
                adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
                useCase: useCaseFlags.useCase,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
            )
        )
    }
}

struct ArraySchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "array-schema",
        abstract: "Run a runtime-defined array schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "todo"

    @Option(name: .customLong("min-items"), help: "Minimum number of generated items.")
    var minimumItems = 2

    @Option(name: .customLong("max-items"), help: "Maximum number of generated items.")
    var maximumItems = 5

    mutating func run() async throws {
        let resolvedMinimumItems = minimumItems
        let resolvedMaximumItems = maximumItems
        try await runDynamicSchemaCommand(
            DynamicSchemaCommandRequest(
                command: "schema run array-schema",
                exampleID: "array-schema",
                presetID: preset,
                inputSource: inputSource,
                schemaBuilder: { presetID in
                    try makeArraySchema(
                        presetID: presetID,
                        minimumItems: resolvedMinimumItems,
                        maximumItems: resolvedMaximumItems
                    )
                },
                options: options,
                generation: generation,
                adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
                useCase: useCaseFlags.useCase,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
            )
        )
    }
}

struct EnumSchemaCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "enum-schema",
        abstract: "Run a runtime-defined enum schema workflow."
    )

    @OptionGroup var options: GlobalCommandOptions
    @OptionGroup var generation: GenerationFlags
    @OptionGroup var adapterOptions: AdapterOptions
    @OptionGroup var useCaseFlags: ModelUseCaseFlags
    @OptionGroup var schemaPromptFlags: SchemaPromptFlags
    @OptionGroup var inputSource: InputSourceOptions

    @Option(name: .long, help: "Preset to use.")
    var preset = "sentiment"

    @Option(name: .customLong("choice"), parsing: .upToNextOption, help: "Custom enum choices. Repeat the option for multiple values.")
    var choice: [String] = []

    mutating func run() async throws {
        let customChoices = choice
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        try await runDynamicSchemaCommand(
            DynamicSchemaCommandRequest(
                command: "schema run enum-schema",
                exampleID: "enum-schema",
                presetID: preset,
                inputSource: inputSource,
                schemaBuilder: { presetID in
                    try makeEnumSchema(
                        presetID: presetID,
                        customChoices: customChoices
                    )
                },
                options: options,
                generation: generation,
                adapterPath: try adapterOptions.resolveAdapterPath(guardrails: generation.guardrails),
                useCase: useCaseFlags.useCase,
                includeSchemaInPrompt: schemaPromptFlags.includeSchemaInPrompt
            )
        )
    }
}

private struct DynamicSchemaCommandRequest {
    let command: String
    let exampleID: String
    let presetID: String
    let inputSource: InputSourceOptions
    let schemaBuilder: (String) throws -> GenerationSchema
    let options: GlobalCommandOptions
    let generation: GenerationFlags
    let adapterPath: String?
    let useCase: FoundationModelUseCase
    let includeSchemaInPrompt: Bool
}

private func runDynamicSchemaCommand(
    _ request: DynamicSchemaCommandRequest
) async throws {
    let resolvedOutput = try request.options.resolvedOutput()
    let generationOptions = try request.generation.validatedOptions()
    guard let example = AFMSchemaCatalog.example(id: request.exampleID) else {
        throw AFMRuntimeError.invalidRequest("Unknown schema example: \(request.exampleID)")
    }
    guard let preset = example.presets.first(where: { $0.id == request.presetID }) else {
        throw ValidationError("Unknown preset '\(request.presetID)' for \(request.exampleID)")
    }
    let resolvedInput = try request.inputSource.resolve(defaultValue: preset.defaultInput)

    if request.options.dryRun {
        try CLIOutput.emit(
            payload: DryRunPayload(
                command: request.command,
                adapter: request.adapterPath,
                preset: request.presetID,
                input: resolvedInput.value,
                inputFile: resolvedInput.file,
                useCase: request.useCase.rawValue,
                guardrails: request.generation.guardrails.afmArgumentValue,
                includeSchemaInPrompt: request.includeSchemaInPrompt
            ),
            human: "[dry-run] afm \(request.command)\nPreset: \(request.presetID)\nInput: \(resolvedInput.value)",
            options: resolvedOutput
        )
        return
    }

    _ = try requireFoundationModelsAvailability(
        useCase: request.useCase,
        adapterPath: request.adapterPath
    )
    let result = try await FoundationModelDynamicSchemaGenerationUseCase().execute(
        FoundationModelDynamicSchemaGenerationRequest(
            prompt: resolvedInput.value,
            schema: try request.schemaBuilder(request.presetID),
            systemPrompt: request.generation.systemPrompt,
            modelUseCase: request.useCase,
            guardrails: request.generation.guardrails,
            adapterURL: adapterURL(from: request.adapterPath),
            generationOptions: generationOptions,
            includeSchemaInPrompt: request.includeSchemaInPrompt,
            context: afmContext()
        )
    )
    try emitDynamicSchemaResult(
        result,
        request: request,
        example: example,
        resolvedInput: resolvedInput,
        outputOptions: resolvedOutput
    )
}

private func emitDynamicSchemaResult(
    _ result: FoundationModelDynamicSchemaGenerationResult,
    request: DynamicSchemaCommandRequest,
    example: AFMSchemaExampleDescriptor,
    resolvedInput: ResolvedTextInput,
    outputOptions: CLIOutputOptions
) throws {
    let payload = DynamicSchemaPayload(
        command: request.command,
        adapter: request.adapterPath,
        preset: request.presetID,
        useCase: request.useCase.rawValue,
        guardrails: request.generation.guardrails.afmArgumentValue,
        includeSchemaInPrompt: request.includeSchemaInPrompt,
        input: resolvedInput.value,
        json: result.output.jsonString,
        tokenCount: result.metadata.tokenCount,
        schemaFile: nil
    )
    let human = """
    \(example.title)

    \(result.output.jsonString)
    """
    let renderedHuman = verboseHumanOutput(
        human,
        tokenCount: result.metadata.tokenCount,
        verbose: request.options.verbose
    )
    try CLIOutput.emit(payload: payload, human: renderedHuman, options: outputOptions)
}
