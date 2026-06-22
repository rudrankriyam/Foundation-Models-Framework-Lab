import Foundation

/// The JSON Schema subset supported by Apple's dynamic Foundation Models schemas.
public final class FoundationModelsJSONSchema: Codable, Equatable, Sendable {
  /// A resolved schema value type.
  public enum ValueType: String, Sendable, Equatable {
    case object
    case array
    case string
    case integer
    case number
    case boolean
  }

  public let title: String?
  public let description: String?
  public let type: String?
  public let properties: [String: FoundationModelsJSONSchema]?
  public let required: [String]?
  public let additionalProperties: Bool?
  public let items: FoundationModelsJSONSchema?
  public let minimumItems: Int?
  public let maximumItems: Int?
  public let enumValues: [String]?

  public init(
    title: String? = nil,
    description: String? = nil,
    type: String? = nil,
    properties: [String: FoundationModelsJSONSchema]? = nil,
    required: [String]? = nil,
    additionalProperties: Bool? = nil,
    items: FoundationModelsJSONSchema? = nil,
    minimumItems: Int? = nil,
    maximumItems: Int? = nil,
    enumValues: [String]? = nil
  ) {
    self.title = title
    self.description = description
    self.type = type
    self.properties = properties
    self.required = required
    self.additionalProperties = additionalProperties
    self.items = items
    self.minimumItems = minimumItems
    self.maximumItems = maximumItems
    self.enumValues = enumValues
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: AnyCodingKey.self)
    let schemaPath = Self.jsonPath(for: decoder.codingPath)

    if let unsupportedKey = container.allKeys
      .map(\.stringValue)
      .filter({ !Self.supportedKeywords.contains($0) })
      .sorted()
      .first {
      throw FoundationModelsJSONSchemaError(
        kind: .unsupportedKeyword,
        path: Self.appending(unsupportedKey, to: schemaPath),
        message: "Unsupported JSON Schema keyword '\(unsupportedKey)'."
      )
    }

    title = try Self.decode(String.self, forKey: .title, from: container, at: schemaPath)
    description = try Self.decode(String.self, forKey: .description, from: container, at: schemaPath)
    type = try Self.decode(String.self, forKey: .type, from: container, at: schemaPath)
    properties = try Self.decode(
      [String: FoundationModelsJSONSchema].self,
      forKey: .properties,
      from: container,
      at: schemaPath
    )
    required = try Self.decode([String].self, forKey: .required, from: container, at: schemaPath)
    additionalProperties = try Self.decode(Bool.self, forKey: .additionalProperties, from: container, at: schemaPath)
    items = try Self.decode(FoundationModelsJSONSchema.self, forKey: .items, from: container, at: schemaPath)
    minimumItems = try Self.decode(Int.self, forKey: .minimumItems, from: container, at: schemaPath)
    maximumItems = try Self.decode(Int.self, forKey: .maximumItems, from: container, at: schemaPath)
    enumValues = try Self.decode([String].self, forKey: .enumValues, from: container, at: schemaPath)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encodeIfPresent(description, forKey: .description)
    try container.encodeIfPresent(type, forKey: .type)
    try container.encodeIfPresent(properties, forKey: .properties)
    try container.encodeIfPresent(required, forKey: .required)
    try container.encodeIfPresent(additionalProperties, forKey: .additionalProperties)
    try container.encodeIfPresent(items, forKey: .items)
    try container.encodeIfPresent(minimumItems, forKey: .minimumItems)
    try container.encodeIfPresent(maximumItems, forKey: .maximumItems)
    try container.encodeIfPresent(enumValues, forKey: .enumValues)
  }

  public static func == (lhs: FoundationModelsJSONSchema, rhs: FoundationModelsJSONSchema) -> Bool {
    lhs.title == rhs.title
      && lhs.description == rhs.description
      && lhs.type == rhs.type
      && lhs.properties == rhs.properties
      && lhs.required == rhs.required
      && lhs.additionalProperties == rhs.additionalProperties
      && lhs.items == rhs.items
      && lhs.minimumItems == rhs.minimumItems
      && lhs.maximumItems == rhs.maximumItems
      && lhs.enumValues == rhs.enumValues
  }
}

extension FoundationModelsJSONSchema {
  private enum CodingKeys: String, CodingKey, CaseIterable {
    case title
    case description
    case type
    case properties
    case required
    case additionalProperties
    case items
    case minimumItems = "minItems"
    case maximumItems = "maxItems"
    case enumValues = "enum"
  }

  private struct AnyCodingKey: CodingKey {
    let stringValue: String
    let intValue: Int?

    init?(stringValue: String) {
      self.stringValue = stringValue
      self.intValue = nil
    }

    init?(intValue: Int) {
      self.stringValue = String(intValue)
      self.intValue = intValue
    }
  }

  private static let supportedKeywords = Set(CodingKeys.allCases.map(\.rawValue))

  private static func decode<Value: Decodable>(
    _ type: Value.Type,
    forKey key: CodingKeys,
    from container: KeyedDecodingContainer<AnyCodingKey>,
    at schemaPath: String
  ) throws -> Value? {
    guard let codingKey = AnyCodingKey(stringValue: key.rawValue) else {
      return nil
    }

    do {
      return try container.decodeIfPresent(type, forKey: codingKey)
    } catch let error as FoundationModelsJSONSchemaError {
      throw error
    } catch {
      throw FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: appending(key.rawValue, to: schemaPath),
        message: "Keyword '\(key.rawValue)' has an invalid value."
      )
    }
  }

  static func jsonPath(for codingPath: [CodingKey]) -> String {
    let schemaPathStart = codingPath.firstIndex {
      $0.stringValue == CodingKeys.properties.rawValue || $0.stringValue == CodingKeys.items.rawValue
    }
    let schemaCodingPath = schemaPathStart.map { codingPath[$0...] } ?? codingPath[codingPath.endIndex...]
    return schemaCodingPath.reduce("$") { path, key in
      if let index = key.intValue {
        return "\(path)[\(index)]"
      }
      return appending(key.stringValue, to: path)
    }
  }

  static func appending(_ component: String, to path: String) -> String {
    let isIdentifier = component.first?.isLetter == true
      && component.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    if isIdentifier {
      return "\(path).\(component)"
    }
    let escaped = component
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\(path)[\"\(escaped)\"]"
  }
}
