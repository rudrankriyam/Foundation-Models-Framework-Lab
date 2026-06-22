import ArgumentParser
import Foundation
import FoundationModels
import Yams

enum AFMArtifactRegistry {
    static func loadSchemaDocument(from reference: ResolvedArtifactReference) throws -> AFMSchemaDocument {
        let text = try String(contentsOfFile: reference.filePath, encoding: .utf8)
        return try decodeArtifact(AFMSchemaDocument.self, from: text, path: reference.filePath)
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
                if let schemaError = AFMSchemaValidationError.find(in: error) {
                    throw ValidationError("Schema validation failed in \(path): \(schemaError.localizedDescription)")
                }
                throw ValidationError("Could not decode \(path) as YAML: \(error.localizedDescription)")
            }
        default:
            do {
                let data = Data(text.utf8)
                return try JSONDecoder().decode(type, from: data)
            } catch {
                if let schemaError = AFMSchemaValidationError.find(in: error) {
                    throw ValidationError("Schema validation failed in \(path): \(schemaError.localizedDescription)")
                }
                throw ValidationError("Could not decode \(path) as JSON: \(error.localizedDescription)")
            }
        }
    }
}

struct AFMSchemaDocument: Sendable, Codable {
    let title: String?
    let description: String?
    let type: String?
    let properties: [String: AFMSchemaDocumentBox]?
    let required: [String]?
    let items: AFMSchemaDocumentBox?
    let minimumItems: Int?
    let maximumItems: Int?
    let enumValues: [String]?
    let additionalProperties: Bool?

    private enum SchemaCodingKeys: String, CodingKey {
        case title
        case description
        case type
        case properties
        case required
        case items
        case minimumItems = "minItems"
        case maximumItems = "maxItems"
        case enumValues = "enum"
        case definitions = "$defs"
        case reference = "$ref"
        case anyOf
        case propertyOrder = "x-order"
        case additionalProperties
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SchemaCodingKeys.self)

        try Self.rejectUnsupportedKeyword(.definitions, in: container, decoder: decoder)
        try Self.rejectUnsupportedKeyword(.reference, in: container, decoder: decoder)
        try Self.rejectUnsupportedKeyword(.anyOf, in: container, decoder: decoder)
        try Self.rejectUnsupportedKeyword(.propertyOrder, in: container, decoder: decoder)

        if container.contains(.additionalProperties) {
            let value: Bool
            do {
                value = try container.decode(Bool.self, forKey: .additionalProperties)
            } catch {
                throw AFMSchemaValidationError.unsupportedKeyword(
                    SchemaCodingKeys.additionalProperties.rawValue,
                    codingPath: decoder.codingPath,
                    detail: "Only the boolean value false is supported."
                )
            }
            guard !value else {
                throw AFMSchemaValidationError.unsupportedKeyword(
                    SchemaCodingKeys.additionalProperties.rawValue,
                    codingPath: decoder.codingPath,
                    detail: "Only the boolean value false is supported."
                )
            }
            additionalProperties = value
        } else {
            additionalProperties = nil
        }

        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        properties = try container.decodeIfPresent([String: AFMSchemaDocumentBox].self, forKey: .properties)
        required = try container.decodeIfPresent([String].self, forKey: .required)
        items = try container.decodeIfPresent(AFMSchemaDocumentBox.self, forKey: .items)
        minimumItems = try container.decodeIfPresent(Int.self, forKey: .minimumItems)
        maximumItems = try container.decodeIfPresent(Int.self, forKey: .maximumItems)
        enumValues = try container.decodeIfPresent([String].self, forKey: .enumValues)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SchemaCodingKeys.self)
        try container.encodeIfPresent(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(properties, forKey: .properties)
        try container.encodeIfPresent(required, forKey: .required)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(minimumItems, forKey: .minimumItems)
        try container.encodeIfPresent(maximumItems, forKey: .maximumItems)
        try container.encodeIfPresent(enumValues, forKey: .enumValues)
        try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
    }

    func generationSchema(fallbackName: String = "RootSchema") throws -> GenerationSchema {
        try GenerationSchema(root: dynamicSchema(nameHint: title ?? fallbackName), dependencies: [])
    }

    private func dynamicSchema(nameHint: String) throws -> DynamicGenerationSchema {
        if let enumValues, !enumValues.isEmpty {
            return DynamicGenerationSchema(
                name: title ?? nameHint,
                description: description,
                anyOf: enumValues
            )
        }

        let resolvedType = resolvedSchemaType()
        switch resolvedType {
        case "object":
            let properties = self.properties ?? [:]
            let requiredProperties = Set(self.required ?? Array(properties.keys))
            let dynamicProperties = try properties.keys.sorted().map { propertyName in
                guard let propertySchema = properties[propertyName]?.value else {
                    throw ValidationError("Missing schema for property '\(propertyName)'")
                }
                return DynamicGenerationSchema.Property(
                    name: propertyName,
                    description: propertySchema.description,
                    schema: try propertySchema.dynamicSchema(nameHint: propertySchema.title ?? propertyName.camelizedSchemaName()),
                    isOptional: !requiredProperties.contains(propertyName)
                )
            }
            return DynamicGenerationSchema(
                name: title ?? nameHint,
                description: description,
                properties: dynamicProperties
            )
        case "array":
            guard let items = items?.value else {
                throw ValidationError("Array schema '\(title ?? nameHint)' is missing an items definition")
            }
            return DynamicGenerationSchema(
                arrayOf: try items.dynamicSchema(nameHint: items.title ?? "\(nameHint)Item"),
                minimumElements: minimumItems,
                maximumElements: maximumItems
            )
        case "string":
            return DynamicGenerationSchema(type: String.self)
        case "integer":
            return DynamicGenerationSchema(type: Int.self)
        case "number":
            return DynamicGenerationSchema(type: Double.self)
        case "boolean":
            return DynamicGenerationSchema(type: Bool.self)
        default:
            throw ValidationError("Unsupported schema type '\(resolvedType)' in '\(title ?? nameHint)'")
        }
    }

    private func resolvedSchemaType() -> String {
        if let type {
            return type
        }
        if properties != nil {
            return "object"
        }
        if items != nil {
            return "array"
        }
        if enumValues != nil {
            return "string"
        }
        return "object"
    }

    private static func rejectUnsupportedKeyword(
        _ key: SchemaCodingKeys,
        in container: KeyedDecodingContainer<SchemaCodingKeys>,
        decoder: Decoder
    ) throws {
        guard container.contains(key) else {
            return
        }
        throw AFMSchemaValidationError.unsupportedKeyword(
            key.rawValue,
            codingPath: decoder.codingPath
        )
    }
}

private struct AFMSchemaValidationError: LocalizedError {
    let keyword: String
    let jsonPointer: String
    let detail: String

    static func unsupportedKeyword(
        _ keyword: String,
        codingPath: [any CodingKey],
        detail: String = "This keyword is not supported."
    ) -> Self {
        let components = codingPath.map(\.stringValue) + [keyword]
        let pointer = "/" + components.map(jsonPointerEscaped).joined(separator: "/")
        return Self(keyword: keyword, jsonPointer: pointer, detail: detail)
    }

    var errorDescription: String? {
        "Unsupported schema keyword '\(keyword)' at JSON pointer '\(jsonPointer)'. \(detail)"
    }

    static func find(in error: any Error) -> Self? {
        if let schemaError = error as? Self {
            return schemaError
        }

        let underlyingError: (any Error)?
        switch error {
        case DecodingError.dataCorrupted(let context),
             DecodingError.keyNotFound(_, let context),
             DecodingError.typeMismatch(_, let context),
             DecodingError.valueNotFound(_, let context):
            underlyingError = context.underlyingError
        default:
            underlyingError = nil
        }

        guard let underlyingError else {
            return nil
        }
        return find(in: underlyingError)
    }

    private static func jsonPointerEscaped(_ component: String) -> String {
        component
            .replacingOccurrences(of: "~", with: "~0")
            .replacingOccurrences(of: "/", with: "~1")
    }
}

final class AFMSchemaDocumentBox: Codable, @unchecked Sendable {
    let value: AFMSchemaDocument

    init(_ value: AFMSchemaDocument) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        self.value = try AFMSchemaDocument(from: decoder)
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

struct AFMToolManifest: Sendable, Codable {
    let name: String
    let description: String
    let parameters: AFMSchemaDocument
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
        self.parameters = try manifest.parameters.generationSchema(fallbackName: manifest.name.camelizedSchemaName())
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
