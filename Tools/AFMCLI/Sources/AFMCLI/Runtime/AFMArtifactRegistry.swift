import ArgumentParser
import Foundation
import FoundationModels
import FoundationModelsKit
import Yams

enum AFMArtifactRegistry {
    static func loadSchemaDocument(from reference: ResolvedArtifactReference) throws -> FoundationModelsJSONSchema {
        let text = try String(contentsOfFile: reference.filePath, encoding: .utf8)
        return try decodeArtifact(FoundationModelsJSONSchema.self, from: text, path: reference.filePath)
    }

    static func loadToolManifest(from reference: ResolvedArtifactReference) throws -> AFMToolManifest {
        let text = try String(contentsOfFile: reference.filePath, encoding: .utf8)
        return try decodeArtifact(AFMToolManifest.self, from: text, path: reference.filePath)
    }

    static func loadTools(from references: [ResolvedArtifactReference]) throws -> [AFMManifestTool] {
        try references.map { reference in
            try AFMManifestTool(manifest: loadToolManifest(from: reference), sourcePath: reference.filePath)
        }
    }

    private static func decodeArtifact<T: Decodable>(_ type: T.Type, from text: String, path: String) throws -> T {
        let url = URL(fileURLWithPath: path)
        switch url.pathExtension.lowercased() {
        case "yaml", "yml":
            do {
                return try YAMLDecoder().decode(type, from: text)
            } catch {
                throw ValidationError("Could not decode \(path) as YAML: \(error.localizedDescription)")
            }
        default:
            do {
                let data = Data(text.utf8)
                return try JSONDecoder().decode(type, from: data)
            } catch {
                throw ValidationError("Could not decode \(path) as JSON: \(error.localizedDescription)")
            }
        }
    }
}

struct AFMToolManifest: Sendable, Codable {
    let name: String
    let description: String
    let parameters: FoundationModelsJSONSchema
    let runner: AFMToolRunnerManifest
}

struct AFMToolRunnerManifest: Sendable, Codable {
    enum Kind: String, Sendable, Codable {
        case shell
        case `static`
    }

    enum OutputFormat: String, Sendable, Codable {
        case text
        case json
    }

    let kind: Kind
    let outputFormat: OutputFormat?
    let command: String?
    let args: [String]?
    let workingDirectory: String?
    let environment: [String: String]?
    let text: String?
    let json: AFMJSONValue?
}

struct AFMManifestTool: Tool {
    typealias Arguments = GeneratedContent
    typealias Output = GeneratedContent

    let manifest: AFMToolManifest
    let sourcePath: String
    let parameters: GenerationSchema

    init(manifest: AFMToolManifest, sourcePath: String) throws {
        self.manifest = manifest
        self.sourcePath = sourcePath
        self.parameters = try manifest.parameters.generationSchema(rootName: manifest.name.camelizedSchemaName())
    }

    var name: String { manifest.name }
    var description: String { manifest.description }

    func call(arguments: GeneratedContent) async throws -> GeneratedContent {
        switch manifest.runner.kind {
        case .static:
            return try staticOutput()
        case .shell:
            return try await shellOutput(arguments: arguments)
        }
    }

    private func staticOutput() throws -> GeneratedContent {
        switch manifest.runner.outputFormat ?? .json {
        case .json:
            guard let json = manifest.runner.json else {
                throw AFMRuntimeError.invalidRequest("Static tool '\(name)' is missing runner.json output")
            }
            return try GeneratedContent(json: json.jsonString(pretty: false))
        case .text:
            guard let text = manifest.runner.text else {
                throw AFMRuntimeError.invalidRequest("Static tool '\(name)' is missing runner.text output")
            }
            return GeneratedContent(text)
        }
    }

    private func shellOutput(arguments: GeneratedContent) async throws -> GeneratedContent {
        guard let command = manifest.runner.command, !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AFMRuntimeError.invalidRequest("Shell tool '\(name)' is missing runner.command")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: expandedPathString(command))
        process.arguments = manifest.runner.args ?? []
        if let workingDirectory = manifest.runner.workingDirectory, !workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: expandedPathString(workingDirectory))
        }
        process.environment = ProcessInfo.processInfo.environment.merging(manifest.runner.environment ?? [:]) { _, new in new }

        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading
        let outputTask = Task.detached {
            try outputHandle.readToEnd() ?? Data()
        }
        let errorTask = Task.detached {
            try errorHandle.readToEnd() ?? Data()
        }

        let inputData = Data(arguments.jsonString.utf8)
        inputPipe.fileHandleForWriting.write(inputData)
        try? inputPipe.fileHandleForWriting.close()
        process.waitUntilExit()

        let stdout = String(data: try await outputTask.value, encoding: .utf8) ?? ""
        let stderr = String(data: try await errorTask.value, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            let trimmedError = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            let message = trimmedError.isEmpty
                ? "Tool '\(name)' exited with status \(process.terminationStatus)"
                : trimmedError
            throw AFMRuntimeError.providerFailure(message)
        }

        switch manifest.runner.outputFormat ?? .json {
        case .json:
            let trimmed = stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw AFMRuntimeError.providerFailure("Tool '\(name)' returned empty JSON output")
            }
            return try GeneratedContent(json: trimmed)
        case .text:
            let trimmed = stdout.trimmingCharacters(in: .newlines)
            guard !trimmed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw AFMRuntimeError.providerFailure("Tool '\(name)' returned empty text output")
            }
            return GeneratedContent(trimmed)
        }
    }
}

enum AFMJSONValue: Sendable, Codable, Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: AFMJSONValue])
    case array([AFMJSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([String: AFMJSONValue].self) {
            self = .object(value)
        } else if let value = try? container.decode([AFMJSONValue].self) {
            self = .array(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported JSON value")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }

    func jsonString(pretty: Bool) throws -> String {
        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            encoder.outputFormatting = [.sortedKeys]
        }
        let data = try encoder.encode(self)
        guard let text = String(data: data, encoding: .utf8) else {
            throw AFMRuntimeError.providerFailure("Could not encode JSON value")
        }
        return text
    }
}

extension String {
    func camelizedSchemaName() -> String {
        split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map { segment in
                segment.prefix(1).uppercased() + segment.dropFirst()
            }
            .joined()
            .nonEmptyOrFallback("Schema")
    }

    func nonEmptyOrFallback(_ fallback: String) -> String {
        isEmpty ? fallback : self
    }
}
