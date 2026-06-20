import FoundationLabCore

enum ExperimentCodeGenerator {
    static func code(for configuration: FoundationLabExperimentConfiguration) -> String {
        let tools = configuration.selectedTools.map(toolConstructor).joined(separator: ", ")
        let model = modelDeclaration(for: configuration)
        let instructions = swiftLiteral(configuration.instructions)
        let prompt = swiftLiteral(configuration.prompt)
        let context = contextOptions(for: configuration)
        let options = generationOptions(for: configuration)
        let experiment = """
        \(model)
        let tools: [any Tool] = [\(tools)]
        let session = LanguageModelSession(
            model: model,
            tools: tools,
            instructions: Instructions(\(instructions))
        )
        \(options)
        \(context)
        let response = try await session.respond(
            to: Prompt(\(prompt)),
            options: options\(contextArgument(for: configuration))
        )
        print(response.content)
        """

        let imports = """
        import FoundationLabCore
        import FoundationModels
        import FoundationModelsTools
        """

        guard configuration.modelRuntime == .privateCloudCompute else {
            return "\(imports)\n\n\(experiment)"
        }

        return """
        \(imports)

        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
        \(indented(experiment))
        } else {
            print("Private Cloud Compute requires an OS 27 runtime.")
        }
        """
    }

    private static func modelDeclaration(for configuration: FoundationLabExperimentConfiguration) -> String {
        switch configuration.modelRuntime {
        case .onDevice:
            "let model = SystemLanguageModel.default"
        case .privateCloudCompute:
            "let model = PrivateCloudComputeLanguageModel()"
        }
    }

    private static func generationOptions(for configuration: FoundationLabExperimentConfiguration) -> String {
        let generationOptions = configuration.generationOptions
        let sampling: String

        switch generationOptions.sampling {
        case .none:
            sampling = "nil"
        case .greedy:
            sampling = ".greedy"
        case .randomTop(let top, let seed):
            sampling = ".random(top: \(top), seed: \(optionalString(seed)))"
        case .randomProbabilityThreshold(let threshold, let seed):
            sampling = ".random(probabilityThreshold: \(threshold), seed: \(optionalString(seed)))"
        }

        let temperature = optionalString(generationOptions.temperature)
        let maximumResponseTokens = optionalString(generationOptions.maximumResponseTokens)

        return """
        let options = GenerationOptions(
            samplingMode: \(sampling),
            temperature: \(temperature),
            maximumResponseTokens: \(maximumResponseTokens)
        )
        """
    }

    private static func contextOptions(for configuration: FoundationLabExperimentConfiguration) -> String {
        guard configuration.modelRuntime == .privateCloudCompute,
              configuration.reasoningLevel != .none else {
            return ""
        }

        return "let contextOptions = ContextOptions(reasoningLevel: .\(configuration.reasoningLevel.rawValue))"
    }

    private static func contextArgument(for configuration: FoundationLabExperimentConfiguration) -> String {
        configuration.modelRuntime == .privateCloudCompute && configuration.reasoningLevel != .none
            ? ",\n    contextOptions: contextOptions"
            : ""
    }

    private static func toolConstructor(_ tool: FoundationLabBuiltInTool) -> String {
        switch tool {
        case .weather: "WeatherTool()"
        case .web: "Search1WebSearchTool()"
        case .contacts: "ContactsTool()"
        case .calendar: "CalendarTool()"
        case .reminders: "RemindersTool()"
        case .location: "LocationTool()"
        case .health: "HealthTool()"
        case .music: "MusicTool()"
        case .webMetadata: "WebMetadataTool()"
        }
    }

    private static func swiftLiteral(_ value: String) -> String {
        let escaped = value
            .replacing("\\", with: "\\\\")
            .replacing("\"", with: "\\\"")
            .replacing("\n", with: "\\n")
        return "\"\(escaped)\""
    }

    private static func optionalString<T: CustomStringConvertible>(_ value: T?) -> String {
        value.map { String(describing: $0) } ?? "nil"
    }

    private static func indented(_ value: String) -> String {
        value
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "    \($0)" }
            .joined(separator: "\n")
    }
}
