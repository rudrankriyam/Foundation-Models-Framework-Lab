import ArgumentParser
import Foundation

enum AFMSchemaObjectSerializationFormat: String, Sendable {
    case json
    case yaml
}

enum AFMSchemaObjectPropertyKind: Sendable {
    case primitive(String)
    case object(AFMSchemaDocument?)
}

struct AFMSchemaObjectProperty: Sendable {
    let path: [String]
    var kind: AFMSchemaObjectPropertyKind
    var description: String?
    var isOptional = false
    var isArray = false
}

struct AFMSchemaObjectRequest: Sendable {
    enum Mode: Sendable {
        case object([AFMSchemaObjectProperty])
        case union([AFMSchemaDocument])
    }

    let name: String
    let mode: Mode
    let format: AFMSchemaObjectSerializationFormat
}

enum AFMSchemaObjectParser {
    static func parse(_ arguments: [String]) throws -> AFMSchemaObjectRequest {
        var state = ParserState()
        var index = 0

        while index < arguments.count {
            let option = try ParsedOption(arguments[index])
            index += 1
            try consume(option, arguments: arguments, index: &index, state: &state)
        }

        return try state.request()
    }

    private static func consume(
        _ option: ParsedOption,
        arguments: [String],
        index: inout Int,
        state: inout ParserState
    ) throws {
        if try consumeDeclaration(option, arguments: arguments, index: &index, state: &state) {
            return
        }
        if try consumeModifier(option, arguments: arguments, index: &index, state: &state) {
            return
        }

        switch option.name {
        case "name":
            guard state.name == nil else {
                throw ValidationError("Provide --name only once.")
            }
            state.name = try optionValue(option, arguments: arguments, index: &index)
        case "schema":
            let rawSchema = try optionValue(option, arguments: arguments, index: &index)
            try state.appendSchema(try decodeSchema(rawSchema))
        case "anyOf", "any-of":
            try option.requireFlag()
            try state.beginUnion()
        case "format":
            let rawFormat = try optionValue(option, arguments: arguments, index: &index)
            guard let format = AFMSchemaObjectSerializationFormat(rawValue: rawFormat.lowercased()) else {
                throw ValidationError("--format must be json or yaml.")
            }
            state.format = format
        default:
            throw ValidationError("Unknown schema object option '--\(option.name)'.")
        }
    }

    private static func consumeDeclaration(
        _ option: ParsedOption,
        arguments: [String],
        index: inout Int,
        state: inout ParserState
    ) throws -> Bool {
        let type: AFMSchemaObjectPropertyKind
        switch option.name {
        case "string": type = .primitive("string")
        case "integer", "int": type = .primitive("integer")
        case "double": type = .primitive("number")
        case "boolean": type = .primitive("boolean")
        case "object": type = .object(nil)
        default: return false
        }
        let path = try optionValue(option, arguments: arguments, index: &index)
        try state.appendProperty(path: path, kind: type)
        return true
    }

    private static func consumeModifier(
        _ option: ParsedOption,
        arguments: [String],
        index: inout Int,
        state: inout ParserState
    ) throws -> Bool {
        switch option.name {
        case "array":
            try option.requireFlag()
            try state.modifyCurrentProperty { property in
                guard !property.isArray else {
                    throw ValidationError("Apply --array to a property only once.")
                }
                property.isArray = true
            }
        case "description":
            let description = try optionValue(option, arguments: arguments, index: &index)
            try state.modifyCurrentProperty { property in
                guard property.description == nil else {
                    throw ValidationError("Apply --description to a property only once.")
                }
                property.description = description
            }
        case "optional":
            try option.requireFlag()
            try state.modifyCurrentProperty { property in
                guard !property.isOptional else {
                    throw ValidationError("Apply --optional to a property only once.")
                }
                property.isOptional = true
            }
        default:
            return false
        }
        return true
    }

    private static func optionValue(
        _ option: ParsedOption,
        arguments: [String],
        index: inout Int
    ) throws -> String {
        if let inlineValue = option.inlineValue {
            return try validatedValue(inlineValue, option: option.name)
        }
        guard index < arguments.count, !arguments[index].hasPrefix("--") else {
            throw ValidationError("--\(option.name) requires a value.")
        }
        defer { index += 1 }
        return try validatedValue(arguments[index], option: option.name)
    }

    private static func validatedValue(_ value: String, option: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw ValidationError("--\(option) requires a non-empty value.")
        }
        return trimmed
    }

    private static func decodeSchema(_ rawValue: String) throws -> AFMSchemaDocument {
        guard rawValue.hasPrefix("@") else {
            return try AFMArtifactRegistry.decodeSchemaDocument(from: rawValue)
        }

        let path = expandedPathString(String(rawValue.dropFirst()))
        guard FileManager.default.fileExists(atPath: path) else {
            throw ValidationError("Could not find --schema file at \(path).")
        }
        let url = URL(fileURLWithPath: path)
        return try AFMArtifactRegistry.loadSchemaDocument(
            from: ResolvedArtifactReference(
                rawValue: rawValue,
                identifier: url.deletingPathExtension().lastPathComponent,
                filePath: path,
                directory: url.deletingLastPathComponent().path()
            )
        )
    }
}

private struct ParsedOption {
    let name: String
    let inlineValue: String?

    init(_ argument: String) throws {
        guard argument.hasPrefix("--"), argument.count > 2 else {
            throw ValidationError("Unexpected schema object argument '\(argument)'.")
        }
        let body = argument.dropFirst(2)
        if let separator = body.firstIndex(of: "=") {
            name = String(body[..<separator])
            inlineValue = String(body[body.index(after: separator)...])
        } else {
            name = String(body)
            inlineValue = nil
        }
    }

    func requireFlag() throws {
        guard inlineValue == nil else {
            throw ValidationError("--\(name) does not accept a value.")
        }
    }
}

private struct ParserState {
    var name: String?
    var properties: [AFMSchemaObjectProperty] = []
    var unionSchemas: [AFMSchemaDocument]?
    var currentPropertyIndex: Int?
    var format: AFMSchemaObjectSerializationFormat = .json

    mutating func appendProperty(path: String, kind: AFMSchemaObjectPropertyKind) throws {
        guard unionSchemas == nil else {
            throw ValidationError("Property declarations cannot follow --anyOf.")
        }
        try requireCompletedObjectProperty()
        properties.append(
            AFMSchemaObjectProperty(
                path: try propertyPath(path),
                kind: kind
            )
        )
        currentPropertyIndex = properties.index(before: properties.endIndex)
    }

    mutating func appendSchema(_ schema: AFMSchemaDocument) throws {
        if unionSchemas != nil {
            unionSchemas?.append(schema)
            return
        }
        guard let currentPropertyIndex else {
            throw ValidationError("--schema must follow --object or --anyOf.")
        }
        guard case .object(nil) = properties[currentPropertyIndex].kind else {
            throw ValidationError("--schema must follow an --object property without a schema.")
        }
        properties[currentPropertyIndex].kind = .object(schema)
    }

    mutating func beginUnion() throws {
        guard unionSchemas == nil else {
            throw ValidationError("Provide --anyOf only once.")
        }
        guard properties.isEmpty else {
            throw ValidationError("--anyOf cannot be combined with property declarations.")
        }
        unionSchemas = []
        currentPropertyIndex = nil
    }

    mutating func modifyCurrentProperty(
        _ update: (inout AFMSchemaObjectProperty) throws -> Void
    ) throws {
        guard unionSchemas == nil, let currentPropertyIndex else {
            throw ValidationError("Property modifiers must follow a property declaration.")
        }
        try update(&properties[currentPropertyIndex])
    }

    func request() throws -> AFMSchemaObjectRequest {
        guard let name else {
            throw ValidationError("Please provide --name.")
        }
        try requireCompletedObjectProperty()

        let mode: AFMSchemaObjectRequest.Mode
        if let unionSchemas {
            guard !unionSchemas.isEmpty else {
                throw ValidationError("--anyOf requires at least one --schema.")
            }
            mode = .union(unionSchemas)
        } else {
            mode = .object(properties)
        }
        return AFMSchemaObjectRequest(name: name, mode: mode, format: format)
    }

    private func requireCompletedObjectProperty() throws {
        guard let currentPropertyIndex else {
            return
        }
        if case .object(nil) = properties[currentPropertyIndex].kind {
            let propertyName = properties[currentPropertyIndex].path.joined(separator: ".")
            throw ValidationError("--object '\(propertyName)' must be followed by --schema.")
        }
    }

    private func propertyPath(_ rawValue: String) throws -> [String] {
        let components = rawValue.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard !components.isEmpty,
              components.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw ValidationError("Property paths cannot contain empty components.")
        }
        return components
    }
}
