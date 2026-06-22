import Testing
@testable import FoundationModelsKit

@Suite("Foundation Models JSON Schema Validation")
struct FoundationModelsJSONSchemaValidationTests {
  @Test("String enums must be nonempty and unique")
  func stringEnumsAreValidated() {
    let empty = FoundationModelsJSONSchema(type: "string", enumValues: [])
    let duplicate = FoundationModelsJSONSchema(type: "string", enumValues: ["red", "red"])

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.enum",
        message: "String enum must contain at least one value."
      )
    ) {
      try empty.validate()
    }
    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.enum[1]",
        message: "Enum value 'red' appears more than once."
      )
    ) {
      try duplicate.validate()
    }
  }

  @Test("Enums are limited to string schemas")
  func enumTypeIsValidated() {
    let schema = FoundationModelsJSONSchema(type: "integer", enumValues: ["1"])

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.enum",
        message: "Only string schemas may define enum values."
      )
    ) {
      try schema.validate()
    }
  }

  @Test("Arrays require items and valid bounds")
  func arrayRulesAreValidated() {
    let missingItems = FoundationModelsJSONSchema(type: "array")
    let negativeMinimum = FoundationModelsJSONSchema(
      type: "array",
      items: FoundationModelsJSONSchema(type: "string"),
      minimumItems: -1
    )
    let invertedBounds = FoundationModelsJSONSchema(
      type: "array",
      items: FoundationModelsJSONSchema(type: "string"),
      minimumItems: 3,
      maximumItems: 2
    )

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.items",
        message: "Array schemas must define items."
      )
    ) {
      try missingItems.validate()
    }
    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.minItems",
        message: "minItems must be zero or greater."
      )
    ) {
      try negativeMinimum.validate()
    }
    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.maxItems",
        message: "maxItems must be greater than or equal to minItems."
      )
    ) {
      try invertedBounds.validate()
    }
  }

  @Test("Keywords are rejected when used with the wrong type")
  func typeSpecificKeywordsAreValidated() {
    let schema = FoundationModelsJSONSchema(
      type: "string",
      items: FoundationModelsJSONSchema(type: "boolean")
    )

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.items",
        message: "Keyword 'items' is not valid for a string schema."
      )
    ) {
      try schema.validate()
    }
  }

  @Test("Supported types can be inferred from structural keywords")
  func schemaTypesAreInferred() throws {
    let object = FoundationModelsJSONSchema(properties: [:])
    let array = FoundationModelsJSONSchema(items: FoundationModelsJSONSchema(type: "number"))
    let enumeration = FoundationModelsJSONSchema(enumValues: ["high", "low"])

    #expect(try object.resolvedType() == .object)
    #expect(try array.resolvedType() == .array)
    #expect(try enumeration.resolvedType() == .string)
  }
}
