import Foundation
import Testing
@testable import FoundationModelsKit

@Suite("Foundation Models JSON Schema Decoding")
struct FoundationModelsJSONSchemaDecodingTests {
  @Test("Supported schemas round-trip through deterministic JSON")
  func supportedSchemaRoundTrips() throws {
    let schema = FoundationModelsJSONSchema(
      title: "Person",
      type: "object",
      properties: ["name": FoundationModelsJSONSchema(type: "string")],
      required: ["name"],
      additionalProperties: false
    )

    let json = try schema.jsonString()
    let decoded = try JSONDecoder().decode(FoundationModelsJSONSchema.self, from: Data(json.utf8))

    let expectedJSON = #"{"additionalProperties":false,"properties":{"name":{"type":"string"}},"#
      + #""required":["name"],"title":"Person","type":"object"}"#
    #expect(json == expectedJSON)
    #expect(decoded == schema)
  }

  @Test("Unsupported root keywords are rejected relative to the schema root")
  func unsupportedRootKeyword() throws {
    let data = Data(
      #"{"schema":{"type":"object","$defs":{}}}"#.utf8
    )

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .unsupportedKeyword,
        path: #"$["$defs"]"#,
        message: "Unsupported JSON Schema keyword '$defs'."
      )
    ) {
      try JSONDecoder().decode(SchemaEnvelope.self, from: data)
    }
  }

  @Test("Unsupported nested keywords report their complete schema path")
  func unsupportedNestedKeyword() throws {
    let json = #"{"type":"object","properties":{"profile":{"type":"object","#
      + #""properties":{"name":{"type":"string","pattern":"^[A-Z]"}}}}}"#
    let data = Data(json.utf8)

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .unsupportedKeyword,
        path: "$.properties.profile.properties.name.pattern",
        message: "Unsupported JSON Schema keyword 'pattern'."
      )
    ) {
      try JSONDecoder().decode(FoundationModelsJSONSchema.self, from: data)
    }
  }

  @Test("Invalid keyword value types produce typed errors")
  func invalidKeywordValueType() throws {
    let data = Data(#"{"type":"array","items":{"type":"string"},"minItems":"two"}"#.utf8)

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.minItems",
        message: "Keyword 'minItems' has an invalid value."
      )
    ) {
      try JSONDecoder().decode(FoundationModelsJSONSchema.self, from: data)
    }
  }

  @Test("Required entries must be unique and refer to declared properties")
  func requiredEntriesAreValidated() {
    let property = FoundationModelsJSONSchema(type: "string")
    let duplicate = FoundationModelsJSONSchema(
      type: "object",
      properties: ["name": property],
      required: ["name", "name"]
    )
    let unknown = FoundationModelsJSONSchema(
      type: "object",
      properties: ["name": property],
      required: ["missing"]
    )

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.required[1]",
        message: "Required property 'name' appears more than once."
      )
    ) {
      try duplicate.validate()
    }
    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.required[0]",
        message: "Required property 'missing' is not declared in properties."
      )
    ) {
      try unknown.validate()
    }
  }

  @Test("Only false additionalProperties is accepted")
  func additionalPropertiesMustBeFalse() {
    let schema = FoundationModelsJSONSchema(type: "object", additionalProperties: true)

    #expect(
      throws: FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$.additionalProperties",
        message: "additionalProperties must be false."
      )
    ) {
      try schema.validate()
    }
  }

  private struct SchemaEnvelope: Decodable {
    let schema: FoundationModelsJSONSchema
  }
}
