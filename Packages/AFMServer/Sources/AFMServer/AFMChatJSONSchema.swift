import Foundation
import FoundationModels
import FoundationModelsKit

/// An OpenAI-compatible named JSON schema for a chat completion response.
public struct AFMChatJSONSchema: Sendable, Equatable {
    public let name: String
    public let description: String?
    public let strict: Bool
    public let schema: FoundationModelsJSONSchema

    public init(
        name: String,
        description: String? = nil,
        strict: Bool = false,
        schema: FoundationModelsJSONSchema
    ) {
        self.name = name
        self.description = description
        self.strict = strict
        self.schema = schema
    }

    /// Builds the Foundation Models generation schema using the response format name as its root name.
    public func generationSchema() throws -> GenerationSchema {
        try schema.generationSchema(rootName: name, rootDescription: description)
    }

    /// Returns a stable, sorted-key JSON representation of the schema.
    public func canonicalSchemaJSON() throws -> String {
        try schema.jsonString()
    }
}

extension AFMChatJSONSchema: Decodable {
    private static let allowedFields: Set<String> = ["name", "description", "schema", "strict"]
    private static let schemaParameter = "response_format.json_schema.schema"

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)

        let name = try Self.decodeRequired(
            String.self,
            field: "name",
            from: container,
            decoder: decoder
        )
        guard (1...64).contains(name.count), name.allSatisfy(Self.isAllowedNameCharacter) else {
            let message = "response_format.json_schema.name must be 1 to 64 characters "
                + "and contain only letters, numbers, underscores, or hyphens."
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "name"),
                message: message
            )
        }

        let description = try container.decodeIfPresent(
            String.self,
            forKey: AFMJSONKey("description")
        )
        let strict = try Self.decodeStrict(from: container)
        let schema: FoundationModelsJSONSchema
        do {
            schema = try Self.decodeRequired(
                FoundationModelsJSONSchema.self,
                field: "schema",
                from: container,
                decoder: decoder
            )
            try schema.validate()
        } catch let error as FoundationModelsJSONSchemaError {
            throw Self.requestValidationError(for: error)
        }

        guard try schema.resolvedType() == .object else {
            throw AFMChatRequestValidationError.invalidField(
                "\(Self.schemaParameter).type",
                message: "The root response schema must have type 'object'."
            )
        }
        try Self.validateObjectConstraints(schema, strict: strict, at: Self.schemaParameter)

        self.init(name: name, description: description, strict: strict, schema: schema)
    }

    private static func decodeRequired<Value: Decodable>(
        _ type: Value.Type,
        field: String,
        from container: KeyedDecodingContainer<AFMJSONKey>,
        decoder: Decoder
    ) throws -> Value {
        let key = AFMJSONKey(field)
        guard container.contains(key) else {
            throw AFMChatRequestValidationError.missingField(
                parameterPath(decoder.codingPath, field: field)
            )
        }
        return try container.decode(type, forKey: key)
    }

    private static func decodeStrict(
        from container: KeyedDecodingContainer<AFMJSONKey>
    ) throws -> Bool {
        let key = AFMJSONKey("strict")
        guard container.contains(key) else {
            return false
        }
        return try container.decode(Bool.self, forKey: key)
    }

    private static func isAllowedNameCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "_" || character == "-")
    }

    private static func requestValidationError(
        for error: FoundationModelsJSONSchemaError
    ) -> AFMChatRequestValidationError {
        let suffix = error.path == "$" ? "" : String(error.path.dropFirst())
        let parameter = schemaParameter + suffix
        let code = error.kind == .unsupportedKeyword ? "unsupported_field" : "invalid_field"
        return AFMChatRequestValidationError(
            message: error.message,
            parameter: parameter,
            code: code
        )
    }

    private static func validateObjectConstraints(
        _ schema: FoundationModelsJSONSchema,
        strict: Bool,
        at path: String
    ) throws {
        if try schema.resolvedType() == .object {
            if schema.additionalProperties == true {
                throw AFMChatRequestValidationError.invalidField(
                    "\(path).additionalProperties",
                    message: "additionalProperties must be false when provided."
                )
            }
            if strict, schema.additionalProperties != false {
                throw AFMChatRequestValidationError.invalidField(
                    "\(path).additionalProperties",
                    message: "Strict response schemas must set additionalProperties to false for every object."
                )
            }
            let propertyNames = Set(schema.properties?.keys.map(\.self) ?? [])
            if strict, Set(schema.required ?? []) != propertyNames {
                throw AFMChatRequestValidationError.invalidField(
                    "\(path).required",
                    message: "Strict response schemas must list every object property in required."
                )
            }
            for (name, property) in schema.properties ?? [:] {
                try validateObjectConstraints(
                    property,
                    strict: strict,
                    at: appendingProperty(name, to: path)
                )
            }
        }
        if let items = schema.items {
            try validateObjectConstraints(items, strict: strict, at: "\(path).items")
        }
    }

    private static func appendingProperty(_ name: String, to path: String) -> String {
        let propertiesPath = "\(path).properties"
        let isIdentifier = name.first?.isLetter == true
            && name.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
        guard !isIdentifier else {
            return "\(propertiesPath).\(name)"
        }
        let escapedName = name
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\(propertiesPath)[\"\(escapedName)\"]"
    }
}
