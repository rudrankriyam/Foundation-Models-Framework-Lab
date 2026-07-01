import ArgumentParser
import Foundation
import FoundationModelsKit

struct ResolvedTextInput: Sendable, Encodable {
    enum SourceKind: String, Sendable, Encodable {
        case inline
        case file
        case stdin
    }

    let value: String
    let source: SourceKind
    let file: String?
}

struct PromptInputOptions: ParsableArguments {
    @Option(name: .long, help: "Prompt text to send. Prefix the value with @ to read from a file.")
    var prompt: String?

    @Option(name: .customLong("prompt-file"), help: "Read the prompt from a file path.")
    var promptFile: String?

    @Flag(name: .long, help: "Read the prompt from standard input.")
    var stdin = false

    func resolve(required: Bool = true) throws -> ResolvedTextInput? {
        try resolveSingleInput(
            SingleInputRequest(
                inlineValue: prompt,
                fileValue: promptFile,
                stdin: stdin,
                inlineOptionName: "--prompt",
                fileOptionName: "--prompt-file",
                requiredMessage: "Please provide --prompt, --prompt-file, or stdin."
            )
        )
    }
}

struct InputSourceOptions: ParsableArguments {
    @Option(name: .long, help: "Input text to analyze. Prefix the value with @ to read from a file.")
    var input: String?

    @Option(name: .customLong("input-file"), help: "Read the input from a file path.")
    var inputFile: String?

    @Flag(name: .long, help: "Read the input from standard input.")
    var stdin = false

    func resolve(defaultValue: String? = nil) throws -> ResolvedTextInput {
        if input != nil || inputFile != nil || stdin {
            if let resolved = try resolveSingleInput(
                SingleInputRequest(
                    inlineValue: input,
                    fileValue: inputFile,
                    stdin: stdin,
                    inlineOptionName: "--input",
                    fileOptionName: "--input-file",
                    requiredMessage: "Please provide --input, --input-file, or stdin.",
                    allowAutomaticStdin: false
                )
            ) {
                return resolved
            }
        }

        if shouldAutomaticallyReadFromStdin(),
           let resolved = try readOptionalStandardInput(optionName: "--stdin") {
            return resolved
        }

        if let defaultValue {
            let trimmed = try validatedResolvedText(defaultValue, optionName: "--input")
            return ResolvedTextInput(value: trimmed, source: .inline, file: nil)
        }

        throw ValidationError("Please provide --input, --input-file, or stdin.")
    }
}

struct SessionOptions: ParsableArguments {
    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Message(s) to send through one shared session. Repeat for multi-turn chat. Prefix values with @ to read from files."
    )
    var message: [String] = []

    @Option(name: .customLong("message-file"), parsing: .upToNextOption, help: "Read one or more chat messages from files.")
    var messageFile: [String] = []

    @Flag(name: .long, help: "Read one chat message from standard input.")
    var stdin = false

    func resolveMessages() throws -> [ResolvedTextInput] {
        var explicitSourceCount = 0
        if !message.isEmpty { explicitSourceCount += 1 }
        if !messageFile.isEmpty { explicitSourceCount += 1 }
        if stdin { explicitSourceCount += 1 }
        if explicitSourceCount > 1 {
            throw ValidationError("Use only one of --message, --message-file, or --stdin.")
        }

        if !message.isEmpty {
            return try message.map {
                try resolveInlineValue($0, optionName: "--message")
            }
        }

        if !messageFile.isEmpty {
            return try messageFile.map {
                try readFileInput(path: $0, optionName: "--message-file")
            }
        }

        if stdin || shouldAutomaticallyReadFromStdin() {
            return [try readStandardInput(optionName: "--stdin", requiredMessage: "Please provide at least one non-empty --message.")]
        }

        throw ValidationError("Please provide at least one non-empty --message.")
    }
}

struct StreamingOptions: ParsableArguments {
    @Flag(name: .long, help: "Stream each assistant response while it is generated.")
    var stream = false
}

struct ArtifactOutputOptions: ParsableArguments {
    @Option(name: .long, help: "File path to write the exported artifact.")
    var file: String
}

struct SchemaSourceOptions: ParsableArguments {
    @Option(name: .long, help: "Schema identifier or file path. Searches --schema-dir when given a bare identifier.")
    var schema: String?

    @Option(name: .customLong("schema-dir"), help: "Directory used to resolve bare schema identifiers.")
    var schemaDir = ".afm/schemas"

    func resolve() throws -> ResolvedArtifactReference {
        guard let schema else {
            throw ValidationError("Please provide --schema.")
        }
        return try resolveArtifactReference(
            rawValue: schema,
            directory: schemaDir,
            optionName: "--schema",
            directoryOptionName: "--schema-dir"
        )
    }
}

struct ToolSourceOptions: ParsableArguments {
    @Option(
        name: .long,
        parsing: .upToNextOption,
        help: "Tool identifier or file path. Searches --tool-dir for bare identifiers. Repeat to load multiple tools."
    )
    var tool: [String] = []

    @Option(name: .customLong("tool-dir"), help: "Directory used to resolve bare tool identifiers.")
    var toolDir = ".afm/tools"

    func resolveTools() throws -> [ResolvedArtifactReference] {
        try tool.map {
            try resolveArtifactReference(
                rawValue: $0,
                directory: toolDir,
                optionName: "--tool",
                directoryOptionName: "--tool-dir"
            )
        }
    }
}

struct AdapterOptions: ParsableArguments {
    @Option(name: .long, help: "Path to a Foundation Models adapter package (.fmadapter).")
    var adapter: String?

    func resolveAdapterPath(guardrails: FoundationModelGuardrails) throws -> String? {
        guard let adapter else {
            return nil
        }
        guard guardrails == .default else {
            throw ValidationError(
                "--adapter only supports the framework's default guardrails."
            )
        }
        return try validatedAdapterPath(adapter, optionName: "--adapter")
    }
}

struct ResolvedArtifactReference: Sendable, Encodable {
    let rawValue: String
    let identifier: String
    let filePath: String
    let directory: String
}

struct SingleInputRequest {
    let inlineValue: String?
    let fileValue: String?
    let stdin: Bool
    let inlineOptionName: String
    let fileOptionName: String
    let requiredMessage: String
    var allowAutomaticStdin = true
}

func resolveSingleInput(_ request: SingleInputRequest) throws -> ResolvedTextInput? {
    var explicitSourceCount = 0
    if request.inlineValue != nil { explicitSourceCount += 1 }
    if request.fileValue != nil { explicitSourceCount += 1 }
    if request.stdin { explicitSourceCount += 1 }
    if explicitSourceCount > 1 {
        throw ValidationError(
            "Use only one of \(request.inlineOptionName), \(request.fileOptionName), or --stdin."
        )
    }

    if let inlineValue = request.inlineValue {
        return try resolveInlineValue(inlineValue, optionName: request.inlineOptionName)
    }

    if let fileValue = request.fileValue {
        return try readFileInput(path: fileValue, optionName: request.fileOptionName)
    }

    if request.stdin || (request.allowAutomaticStdin && shouldAutomaticallyReadFromStdin()) {
        return try readStandardInput(
            optionName: "--stdin",
            requiredMessage: request.requiredMessage
        )
    }

    return nil
}

func resolveInlineValue(_ value: String, optionName: String) throws -> ResolvedTextInput {
    if let fileReference = extractFileReference(from: value) {
        return try readFileInput(path: fileReference, optionName: optionName)
    }

    let trimmed = try validatedResolvedText(value, optionName: optionName)
    return ResolvedTextInput(value: trimmed, source: .inline, file: nil)
}

func readFileInput(path: String, optionName: String) throws -> ResolvedTextInput {
    let expandedPath = expandedPathString(path)
    let url = URL(fileURLWithPath: expandedPath)

    let data: Data
    do {
        data = try Data(contentsOf: url)
    } catch {
        throw ValidationError("Could not read \(optionName) file at \(expandedPath): \(error.localizedDescription)")
    }

    guard let text = String(data: data, encoding: .utf8) else {
        throw ValidationError("Could not decode \(optionName) file at \(expandedPath) as UTF-8 text.")
    }

    let trimmed = try validatedResolvedText(text, optionName: optionName)
    return ResolvedTextInput(value: trimmed, source: .file, file: expandedPath)
}

func readStandardInput(optionName: String, requiredMessage: String) throws -> ResolvedTextInput {
    guard let resolved = try readOptionalStandardInput(optionName: optionName) else {
        throw ValidationError(requiredMessage)
    }
    return resolved
}

func readOptionalStandardInput(optionName: String) throws -> ResolvedTextInput? {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else {
        throw ValidationError("Could not decode \(optionName) input as UTF-8 text.")
    }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return ResolvedTextInput(value: trimmed, source: .stdin, file: nil)
}

func validatedResolvedText(_ value: String, optionName: String) throws -> String {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedValue.isEmpty else {
        throw ValidationError("Please provide a non-empty \(optionName).")
    }
    return trimmedValue
}

func validatedAdapterPath(_ value: String, optionName: String) throws -> String {
    let trimmedValue = try validatedResolvedText(value, optionName: optionName)
    let expandedPath = expandedPathString(trimmedValue)
    guard URL(fileURLWithPath: expandedPath).pathExtension.lowercased() == "fmadapter" else {
        throw ValidationError("\(optionName) must point to a .fmadapter package.")
    }

    guard FileManager.default.fileExists(atPath: expandedPath) else {
        throw ValidationError("Could not find \(optionName) at \(expandedPath).")
    }

    return expandedPath
}

func shouldAutomaticallyReadFromStdin() -> Bool {
    isatty(fileno(stdin)) == 0
}

func extractFileReference(from value: String) -> String? {
    guard value.hasPrefix("@"), value.count > 1 else {
        return nil
    }
    return String(value.dropFirst())
}

func expandedPathString(_ path: String) -> String {
    NSString(string: path).expandingTildeInPath
}

func resolveArtifactReference(
    rawValue: String,
    directory: String,
    optionName: String,
    directoryOptionName: String
) throws -> ResolvedArtifactReference {
    let trimmedValue = try validatedResolvedText(rawValue, optionName: optionName)
    let expandedDirectory = expandedPathString(directory)
    let candidateExtensions = ["json", "yaml", "yml"]

    if let explicitPath = resolveExplicitArtifactPath(trimmedValue, extensions: candidateExtensions) {
        return ResolvedArtifactReference(
            rawValue: trimmedValue,
            identifier: URL(fileURLWithPath: explicitPath).deletingPathExtension().lastPathComponent,
            filePath: explicitPath,
            directory: expandedDirectory
        )
    }

    let directoryURL = URL(fileURLWithPath: expandedDirectory)
    for `extension` in candidateExtensions {
        let candidate = directoryURL.appending(path: "\(trimmedValue).\(`extension`)")
        if FileManager.default.fileExists(atPath: candidate.path()) {
            return ResolvedArtifactReference(
                rawValue: trimmedValue,
                identifier: trimmedValue,
                filePath: candidate.path(),
                directory: expandedDirectory
            )
        }
    }

    throw ValidationError("Could not resolve \(optionName) '\(trimmedValue)'. Looked in \(directoryOptionName) at \(expandedDirectory).")
}

func resolveExplicitArtifactPath(_ rawValue: String, extensions: [String]) -> String? {
    let expandedValue = expandedPathString(rawValue)
    let fm = FileManager.default

    if fm.fileExists(atPath: expandedValue) {
        return expandedValue
    }

    let pathExtension = URL(fileURLWithPath: expandedValue).pathExtension.lowercased()
    if !pathExtension.isEmpty || expandedValue.contains("/") || expandedValue.hasPrefix(".") {
        for `extension` in extensions {
            let candidate = "\(expandedValue).\(`extension`)"
            if fm.fileExists(atPath: candidate) {
                return candidate
            }
        }
    }

    return nil
}
