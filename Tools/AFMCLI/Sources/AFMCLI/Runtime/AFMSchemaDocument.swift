import Foundation

struct AFMSchemaDocument: Sendable, Codable {
    struct Components: Sendable {
        var title: String?
        var description: String?
        var type: String?
        var properties: [String: AFMSchemaDocumentBox]?
        var required: [String]?
        var items: AFMSchemaDocumentBox?
        var minimumItems: Int?
        var maximumItems: Int?
        var enumValues: [String]?
        var additionalProperties: Bool?
        var definitions: [String: AFMSchemaDocumentBox]?
        var reference: String?
        var anyOf: [AFMSchemaDocumentBox]?
        var propertyOrder: [String]?
    }

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
    let definitions: [String: AFMSchemaDocumentBox]?
    let reference: String?
    let anyOf: [AFMSchemaDocumentBox]?
    let propertyOrder: [String]?

    private enum SchemaCodingKeys: String, CodingKey, CaseIterable {
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

    init(_ components: Components) {
        title = components.title
        description = components.description
        type = components.type
        properties = components.properties
        required = components.required
        items = components.items
        minimumItems = components.minimumItems
        maximumItems = components.maximumItems
        enumValues = components.enumValues
        additionalProperties = components.additionalProperties
        definitions = components.definitions
        reference = components.reference
        anyOf = components.anyOf
        propertyOrder = components.propertyOrder
    }

    init(from decoder: Decoder) throws {
        let rawContainer = try decoder.container(keyedBy: AFMSchemaCodingKey.self)
        let supportedKeywords = Set(SchemaCodingKeys.allCases.map(\.rawValue))
        if let unsupportedKey = rawContainer.allKeys
            .map(\.stringValue)
            .filter({ !supportedKeywords.contains($0) })
            .sorted()
            .first {
            throw AFMSchemaValidationError.unsupportedKeyword(
                unsupportedKey,
                codingPath: decoder.codingPath
            )
        }

        let container = try decoder.container(keyedBy: SchemaCodingKeys.self)
        additionalProperties = try Self.decodeAdditionalProperties(from: container, decoder: decoder)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        type = try container.decodeIfPresent(String.self, forKey: .type)
        properties = try container.decodeIfPresent([String: AFMSchemaDocumentBox].self, forKey: .properties)
        required = try container.decodeIfPresent([String].self, forKey: .required)
        items = try container.decodeIfPresent(AFMSchemaDocumentBox.self, forKey: .items)
        minimumItems = try container.decodeIfPresent(Int.self, forKey: .minimumItems)
        maximumItems = try container.decodeIfPresent(Int.self, forKey: .maximumItems)
        enumValues = try container.decodeIfPresent([String].self, forKey: .enumValues)
        definitions = try container.decodeIfPresent(
            [String: AFMSchemaDocumentBox].self,
            forKey: .definitions
        )
        reference = try container.decodeIfPresent(String.self, forKey: .reference)
        anyOf = try container.decodeIfPresent([AFMSchemaDocumentBox].self, forKey: .anyOf)
        propertyOrder = try container.decodeIfPresent([String].self, forKey: .propertyOrder)
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
        try container.encodeIfPresent(definitions, forKey: .definitions)
        try container.encodeIfPresent(reference, forKey: .reference)
        try container.encodeIfPresent(anyOf, forKey: .anyOf)
        try container.encodeIfPresent(propertyOrder, forKey: .propertyOrder)
    }

    private static func decodeAdditionalProperties(
        from container: KeyedDecodingContainer<SchemaCodingKeys>,
        decoder: Decoder
    ) throws -> Bool? {
        guard container.contains(.additionalProperties) else {
            return nil
        }
        guard let value = try? container.decode(Bool.self, forKey: .additionalProperties), !value else {
            throw AFMSchemaValidationError.unsupportedKeyword(
                SchemaCodingKeys.additionalProperties.rawValue,
                codingPath: decoder.codingPath,
                detail: "Only the boolean value false is supported."
            )
        }
        return value
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
