import Foundation
import FoundationModels
import Testing
@testable import FoundationModelsKit

@Suite("Foundation Models JSON Schema Generation")
struct JSONSchemaGenerationTests {
  @Test("The complete supported dialect converts to a generation schema")
  func supportedDialectConverts() throws {
    let schema = FoundationModelsJSONSchema(
      type: "object",
      properties: [
        "active": FoundationModelsJSONSchema(type: "boolean"),
        "count": FoundationModelsJSONSchema(type: "integer"),
        "label": FoundationModelsJSONSchema(type: "string", enumValues: ["new", "done"]),
        "scores": FoundationModelsJSONSchema(
          type: "array",
          items: FoundationModelsJSONSchema(type: "number"),
          minimumItems: 0,
          maximumItems: 3
        )
      ],
      required: ["active", "count", "label", "scores"],
      additionalProperties: false
    )

    _ = try schema.generationSchema(rootName: "task result")
  }

  @Test("Repeated nested leaf names receive path-unique type names")
  func repeatedNestedLeafNamesConvert() throws {
    let leaf = FoundationModelsJSONSchema(
      type: "object",
      properties: ["value": FoundationModelsJSONSchema(type: "string")],
      required: ["value"]
    )
    let branch = FoundationModelsJSONSchema(
      type: "object",
      properties: ["details": leaf],
      required: ["details"]
    )
    let schema = FoundationModelsJSONSchema(
      type: "object",
      properties: ["primary": branch, "secondary": branch],
      required: ["primary", "secondary"]
    )

    let generationSchema = try schema.generationSchema(rootName: "response")

    #expect(generationSchema.debugDescription.contains("ResponsePrimaryDetails"))
    #expect(generationSchema.debugDescription.contains("ResponseSecondaryDetails"))
  }

  @Test("Root names are converted into valid Foundation Models type names")
  func rootNameIsConverted() throws {
    let schema = FoundationModelsJSONSchema(
      type: "object",
      properties: ["value": FoundationModelsJSONSchema(type: "string")]
    )

    let generationSchema = try schema.generationSchema(rootName: "123 response-format")

    #expect(generationSchema.debugDescription.contains("Schema123ResponseFormat"))
  }

  @Test("Document titles take precedence over caller root names")
  func documentTitleTakesPrecedence() throws {
    let objectSchema = FoundationModelsJSONSchema(
      title: "Echo Payload",
      type: "object",
      properties: [:]
    )
    let enumSchema = FoundationModelsJSONSchema(
      title: "Delivery State",
      type: "string",
      enumValues: ["queued", "sent"]
    )

    let objectGenerationSchema = try objectSchema.generationSchema(rootName: "caller object")
    let enumGenerationSchema = try enumSchema.generationSchema(rootName: "caller enum")

    #expect(objectGenerationSchema.debugDescription.contains("EchoPayload"))
    #expect(!objectGenerationSchema.debugDescription.contains("CallerObject"))
    #expect(enumGenerationSchema.debugDescription.contains("DeliveryState"))
    #expect(!enumGenerationSchema.debugDescription.contains("CallerEnum"))
  }

  @Test("Nested titles retain deterministic collision-safe identities")
  func nestedTitlesResolveCollisions() throws {
    let schema = FoundationModelsJSONSchema(
      title: "Echo Payload",
      type: "object",
      properties: [
        "details": FoundationModelsJSONSchema(
          title: "Echo-Payload",
          type: "object",
          properties: [:]
        ),
        "state": FoundationModelsJSONSchema(
          title: "Echo_Payload",
          type: "string",
          enumValues: ["ready", "done"]
        ),
        "zeta": FoundationModelsJSONSchema(
          title: "Echo Payload",
          type: "object",
          properties: [:]
        )
      ]
    )

    let generationSchema = try schema.generationSchema(rootName: "caller root")

    #expect(generationSchema.debugDescription.contains("EchoPayload"))
    #expect(generationSchema.debugDescription.contains("EchoPayload2"))
    // Apple omits nested enum names from this JSON; the following object proves the enum reserved suffix 3.
    #expect(generationSchema.debugDescription.contains("EchoPayload4"))
    #expect(!generationSchema.debugDescription.contains("CallerRoot"))
  }

  @Test("Converted nested name collisions receive deterministic suffixes")
  func nestedNameCollisionsAreResolved() throws {
    let child = FoundationModelsJSONSchema(type: "object", properties: [:])
    let schema = FoundationModelsJSONSchema(
      type: "object",
      properties: ["alpha beta": child, "alpha-beta": child]
    )

    let generationSchema = try schema.generationSchema(rootName: "result")

    #expect(generationSchema.debugDescription.contains("ResultAlphaBeta"))
    #expect(generationSchema.debugDescription.contains("ResultAlphaBeta2"))
  }

  @Test("Root descriptions override document guidance when provided")
  func rootDescriptionOverride() throws {
    let schema = FoundationModelsJSONSchema(
      description: "Document-level guidance",
      type: "object",
      properties: [:]
    )

    let documentDescription = try schema.generationSchema(rootName: "result")
    let wrapperDescription = try schema.generationSchema(
      rootName: "result",
      rootDescription: "Wrapper-level guidance"
    )

    let documentJSON = try generationSchemaJSON(documentDescription)
    let wrapperJSON = try generationSchemaJSON(wrapperDescription)
    #expect(documentJSON["description"] as? String == "Document-level guidance")
    #expect(wrapperJSON["description"] as? String == "Wrapper-level guidance")
  }

  @Test("Omitting required makes object properties optional")
  func omittedRequiredPropertiesAreOptional() throws {
    let schema = FoundationModelsJSONSchema(
      type: "object",
      properties: ["nickname": FoundationModelsJSONSchema(type: "string")]
    )

    let generationSchema = try schema.generationSchema(rootName: "profile")
    let schemaJSON = try generationSchemaJSON(generationSchema)

    #expect(schemaJSON["required"] as? [String] == [])
  }
}

private func generationSchemaJSON(_ schema: GenerationSchema) throws -> [String: Any] {
  try #require(
    JSONSerialization.jsonObject(with: Data(schema.debugDescription.utf8)) as? [String: Any]
  )
}
