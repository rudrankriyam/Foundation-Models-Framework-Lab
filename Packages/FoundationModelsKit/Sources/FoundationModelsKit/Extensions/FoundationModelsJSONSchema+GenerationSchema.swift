import FoundationModels

extension FoundationModelsJSONSchema {
  /// Converts this document into Apple's dynamic generation schema.
  public func generationSchema(
    rootName: String = "RootSchema",
    rootDescription: String? = nil
  ) throws -> GenerationSchema {
    try validate()

    var converter = Converter(
      rootName: Self.convertedSchemaName(rootName, fallback: "RootSchema"),
      rootDescription: rootDescription
    )
    let root = try converter.convert(self, components: [])
    do {
      return try GenerationSchema(root: root, dependencies: [])
    } catch {
      throw FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$",
        message: "Could not create a Foundation Models generation schema: \(error.localizedDescription)"
      )
    }
  }

  private struct Converter {
    let rootName: String
    let rootDescription: String?
    var allocatedNames = Set<String>()
    var nextSuffixByName: [String: Int] = [:]

    mutating func convert(
      _ document: FoundationModelsJSONSchema,
      components: [String]
    ) throws -> DynamicGenerationSchema {
      switch try document.resolvedType() {
      case .object:
        return try objectSchema(for: document, components: components)
      case .array:
        guard let items = document.items else {
          throw FoundationModelsJSONSchemaError(
            kind: .invalidSchema,
            path: "$.items",
            message: "Array schemas must define items."
          )
        }
        return DynamicGenerationSchema(
          arrayOf: try convert(items, components: components + ["item"]),
          minimumElements: document.minimumItems,
          maximumElements: document.maximumItems
        )
      case .string:
        if let choices = document.enumValues {
          return DynamicGenerationSchema(
            name: allocateName(for: components, title: document.title),
            description: document.description,
            anyOf: choices
          )
        }
        return DynamicGenerationSchema(type: String.self)
      case .integer:
        return DynamicGenerationSchema(type: Int.self)
      case .number:
        return DynamicGenerationSchema(type: Double.self)
      case .boolean:
        return DynamicGenerationSchema(type: Bool.self)
      }
    }

    private mutating func objectSchema(
      for document: FoundationModelsJSONSchema,
      components: [String]
    ) throws -> DynamicGenerationSchema {
      let schemaName = allocateName(for: components, title: document.title)
      let properties = document.properties ?? [:]
      let requiredProperties = Set(document.required ?? [])
      var convertedProperties: [DynamicGenerationSchema.Property] = []

      for propertyName in properties.keys.sorted() {
        guard let propertySchema = properties[propertyName] else {
          continue
        }
        convertedProperties.append(
          DynamicGenerationSchema.Property(
            name: propertyName,
            description: propertySchema.description,
            schema: try convert(propertySchema, components: components + [propertyName]),
            isOptional: !requiredProperties.contains(propertyName)
          )
        )
      }

      return DynamicGenerationSchema(
        name: schemaName,
        description: components.isEmpty ? rootDescription ?? document.description : document.description,
        properties: convertedProperties
      )
    }

    private mutating func allocateName(for components: [String], title: String?) -> String {
      let suffix = components
        .map { FoundationModelsJSONSchema.convertedSchemaName($0, fallback: "Field") }
        .joined()
      let fallbackName = "\(rootName)\(suffix)"
      let preferredName = title.map {
        FoundationModelsJSONSchema.convertedSchemaName($0, fallback: fallbackName)
      } ?? fallbackName
      guard !allocatedNames.contains(preferredName) else {
        var nextSuffix = nextSuffixByName[preferredName, default: 2]
        var candidate = "\(preferredName)\(nextSuffix)"
        while allocatedNames.contains(candidate) {
          nextSuffix += 1
          candidate = "\(preferredName)\(nextSuffix)"
        }
        nextSuffixByName[preferredName] = nextSuffix + 1
        allocatedNames.insert(candidate)
        return candidate
      }

      allocatedNames.insert(preferredName)
      return preferredName
    }
  }

  private static func convertedSchemaName(_ value: String, fallback: String) -> String {
    let converted = value
      .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
      .map { segment in
        segment.prefix(1).uppercased() + segment.dropFirst()
      }
      .joined()
    let nonempty = converted.isEmpty ? fallback : converted
    if nonempty.first?.isNumber == true {
      return "Schema\(nonempty)"
    }
    return nonempty
  }
}
