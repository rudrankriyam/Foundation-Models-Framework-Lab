import Foundation
import FoundationModelsKit

public struct AFMChatToolDefinition: Sendable, Equatable {
    public let name: String
    public let description: String
    public let parameters: FoundationModelsJSONSchema
    public let strict: Bool?

    public init(
        name: String,
        description: String = "",
        parameters: FoundationModelsJSONSchema = .init(type: "object"),
        strict: Bool? = nil
    ) {
        self.name = name
        self.description = description
        self.parameters = parameters
        self.strict = strict
    }
}

extension AFMChatToolDefinition: Decodable {
    private static let allowedFields: Set<String> = ["type", "function"]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        let type = try container.decode(String.self, forKey: .init("type"))
        guard type == "function" else {
            throw AFMChatRequestValidationError.invalidField(
                parameterPath(decoder.codingPath, field: "type"),
                message: "Only function tools are supported."
            )
        }
        let function = try container.decode(Function.self, forKey: .init("function"))
        self = .init(
            name: function.name,
            description: function.description,
            parameters: function.parameters,
            strict: function.strict
        )
    }
}

private struct Function: Decodable {
    let name: String
    let description: String
    let parameters: FoundationModelsJSONSchema
    let strict: Bool?

    private static let allowedFields: Set<String> = ["name", "description", "parameters", "strict"]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        name = try container.decode(String.self, forKey: .init("name"))
        description = try container.decodeIfPresent(String.self, forKey: .init("description")) ?? ""
        strict = try container.decodeIfPresent(Bool.self, forKey: .init("strict"))
        do {
            parameters = try container.decodeIfPresent(
                FoundationModelsJSONSchema.self,
                forKey: .init("parameters")
            ) ?? .init(type: "object")
        } catch let error as FoundationModelsJSONSchemaError {
            throw AFMChatRequestValidationError.toolSchema(
                error,
                parameter: parameterPath(decoder.codingPath, field: "parameters")
            )
        }
    }
}
