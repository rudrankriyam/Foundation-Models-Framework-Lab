import Foundation

/// The output representation requested from a chat completion.
public enum AFMChatResponseFormat: Sendable, Equatable {
    /// Unstructured text output.
    case text

    /// Output constrained by a JSON generation schema.
    case jsonSchema(AFMChatJSONSchema)
}

extension AFMChatResponseFormat: Decodable {
    private static let textFields: Set<String> = ["type"]
    private static let jsonSchemaFields: Set<String> = ["type", "json_schema"]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        let typeKey = AFMJSONKey("type")
        guard container.contains(typeKey) else {
            throw AFMChatRequestValidationError.missingField(
                parameterPath(decoder.codingPath, field: "type")
            )
        }

        let type = try container.decode(String.self, forKey: typeKey)
        switch type {
        case "text":
            try rejectUnknownFields(in: container, allowed: Self.textFields, decoder: decoder)
            self = .text
        case "json_schema":
            try rejectUnknownFields(in: container, allowed: Self.jsonSchemaFields, decoder: decoder)
            let schemaKey = AFMJSONKey("json_schema")
            guard container.contains(schemaKey) else {
                throw AFMChatRequestValidationError.missingField(
                    parameterPath(decoder.codingPath, field: "json_schema")
                )
            }
            self = try .jsonSchema(container.decode(AFMChatJSONSchema.self, forKey: schemaKey))
        case "json_object":
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "response_format type 'json_object' is not supported. Use 'json_schema' instead."
            )
        default:
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "response_format type '\(type)' is not supported."
            )
        }
    }
}
