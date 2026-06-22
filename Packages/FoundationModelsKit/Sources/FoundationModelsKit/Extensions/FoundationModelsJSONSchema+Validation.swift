extension FoundationModelsJSONSchema {
  /// Resolves an explicit or structurally inferred schema type.
  public func resolvedType() throws -> ValueType {
    try resolvedType(at: "$")
  }

  /// Validates the complete document against the supported schema dialect.
  public func validate() throws {
    try validate(at: "$")
  }

  private func validate(at path: String) throws {
    let valueType = try resolvedType(at: path)

    switch valueType {
    case .object:
      try validateObject(at: path)
    case .array:
      try validateArray(at: path)
    case .string:
      try validateScalar(at: path, allowingStringEnum: true)
    case .integer, .number, .boolean:
      try validateScalar(at: path, allowingStringEnum: false)
    }
  }

  private func resolvedType(at path: String) throws -> ValueType {
    if let type {
      guard let valueType = ValueType(rawValue: type) else {
        throw invalid(
          at: Self.appending("type", to: path),
          "Unsupported JSON Schema type '\(type)'."
        )
      }
      return valueType
    }

    if properties != nil || required != nil || additionalProperties != nil {
      return .object
    }
    if items != nil || minimumItems != nil || maximumItems != nil {
      return .array
    }
    if enumValues != nil {
      return .string
    }
    return .object
  }

  private func validateObject(at path: String) throws {
    try rejectKeyword("items", when: items != nil, for: .object, at: path)
    try rejectKeyword("minItems", when: minimumItems != nil, for: .object, at: path)
    try rejectKeyword("maxItems", when: maximumItems != nil, for: .object, at: path)
    try rejectKeyword("enum", when: enumValues != nil, for: .object, at: path)

    if additionalProperties == true {
      throw invalid(
        at: Self.appending("additionalProperties", to: path),
        "additionalProperties must be false."
      )
    }

    let properties = properties ?? [:]
    var requiredNames = Set<String>()
    for (index, propertyName) in (required ?? []).enumerated() {
      let requiredPath = "\(Self.appending("required", to: path))[\(index)]"
      guard requiredNames.insert(propertyName).inserted else {
        throw invalid(at: requiredPath, "Required property '\(propertyName)' appears more than once.")
      }
      guard properties[propertyName] != nil else {
        throw invalid(
          at: requiredPath,
          "Required property '\(propertyName)' is not declared in properties."
        )
      }
    }

    for propertyName in properties.keys.sorted() {
      guard let propertySchema = properties[propertyName] else {
        continue
      }
      let propertiesPath = Self.appending("properties", to: path)
      try propertySchema.validate(at: Self.appending(propertyName, to: propertiesPath))
    }
  }

  private func validateArray(at path: String) throws {
    try rejectKeyword("properties", when: properties != nil, for: .array, at: path)
    try rejectKeyword("required", when: required != nil, for: .array, at: path)
    try rejectKeyword("additionalProperties", when: additionalProperties != nil, for: .array, at: path)
    try rejectKeyword("enum", when: enumValues != nil, for: .array, at: path)

    guard let items else {
      throw invalid(at: Self.appending("items", to: path), "Array schemas must define items.")
    }
    if let minimumItems, minimumItems < 0 {
      throw invalid(at: Self.appending("minItems", to: path), "minItems must be zero or greater.")
    }
    if let maximumItems, maximumItems < 0 {
      throw invalid(at: Self.appending("maxItems", to: path), "maxItems must be zero or greater.")
    }
    if let minimumItems, let maximumItems, maximumItems < minimumItems {
      throw invalid(at: Self.appending("maxItems", to: path), "maxItems must be greater than or equal to minItems.")
    }

    try items.validate(at: Self.appending("items", to: path))
  }

  private func validateScalar(at path: String, allowingStringEnum: Bool) throws {
    let valueType = try resolvedType(at: path)
    try rejectKeyword("properties", when: properties != nil, for: valueType, at: path)
    try rejectKeyword("required", when: required != nil, for: valueType, at: path)
    try rejectKeyword("additionalProperties", when: additionalProperties != nil, for: valueType, at: path)
    try rejectKeyword("items", when: items != nil, for: valueType, at: path)
    try rejectKeyword("minItems", when: minimumItems != nil, for: valueType, at: path)
    try rejectKeyword("maxItems", when: maximumItems != nil, for: valueType, at: path)

    guard let enumValues else {
      return
    }
    guard allowingStringEnum else {
      throw invalid(at: Self.appending("enum", to: path), "Only string schemas may define enum values.")
    }
    guard !enumValues.isEmpty else {
      throw invalid(at: Self.appending("enum", to: path), "String enum must contain at least one value.")
    }

    var uniqueValues = Set<String>()
    for (index, value) in enumValues.enumerated() where !uniqueValues.insert(value).inserted {
      throw invalid(
        at: "\(Self.appending("enum", to: path))[\(index)]",
        "Enum value '\(value)' appears more than once."
      )
    }
  }

  private func rejectKeyword(
    _ keyword: String,
    when isPresent: Bool,
    for valueType: ValueType,
    at path: String
  ) throws {
    guard isPresent else {
      return
    }
    throw invalid(
      at: Self.appending(keyword, to: path),
      "Keyword '\(keyword)' is not valid for a \(valueType.rawValue) schema."
    )
  }

  private func invalid(at path: String, _ message: String) -> FoundationModelsJSONSchemaError {
    FoundationModelsJSONSchemaError(kind: .invalidSchema, path: path, message: message)
  }
}
