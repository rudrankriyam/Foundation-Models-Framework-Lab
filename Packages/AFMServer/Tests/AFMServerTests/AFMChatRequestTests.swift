import Foundation
import Testing
@testable import AFMServer

@Test("Chat requests accept string and typed text content plus the max_tokens alias")
func chatRequestContentAndAlias() throws {
    let request = try decodeChatRequest(
        """
        {
          "model": "system",
          "messages": [
            {"role": "system", "content": "Be concise."},
            {"role": "user", "content": [
              {"type": "text", "text": "First"},
              {"type": "text", "text": "Second"}
            ]}
          ],
          "temperature": 0.5,
          "top_p": 0.9,
          "max_tokens": 42,
          "stream": false
        }
        """
    )

    #expect(request.model == "system")
    #expect(request.messages[1].contentSegments == ["First", "Second"])
    #expect(request.maximumCompletionTokens == 42)
    #expect(request.temperature == 0.5)
    #expect(request.topP == 0.9)
    #expect(!request.stream)
    #expect(request.streamOptions == nil)
    #expect(request.responseFormat == nil)
}

@Test("Chat requests accept omitted, null, and text response formats")
func chatRequestTextResponseFormats() throws {
    let omitted = try decodeChatRequest(validUserRequestJSON)
    let null = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"response_format":null}"#
    )
    let text = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"text"}}"#
    )

    #expect(omitted.responseFormat == nil)
    #expect(null.responseFormat == nil)
    #expect(text.responseFormat == .text)
}

@Test("Chat requests decode non-strict JSON schema response formats")
func chatRequestJSONSchemaResponseFormat() throws {
    let request = try decodeChatRequest(
        #"""
        {
          "messages": [{"role":"user","content":"Hi"}],
          "response_format": {
            "type": "json_schema",
            "json_schema": {
              "name": "answer_1",
              "description": "A concise answer.",
              "schema": {
                "type": "object",
                "properties": {
                  "answer": {"type": "string"},
                  "confidence": {"type": "number"}
                },
                "required": ["answer"]
              }
            }
          }
        }
        """#
    )

    guard case .jsonSchema(let responseSchema) = request.responseFormat else {
        Issue.record("Expected a JSON schema response format")
        return
    }
    #expect(responseSchema.name == "answer_1")
    #expect(responseSchema.description == "A concise answer.")
    #expect(!responseSchema.strict)
    #expect(responseSchema.schema.required == ["answer"])
    #expect(
        try responseSchema.generationSchema().debugDescription.contains("A concise answer.")
    )
    #expect(
        try responseSchema.canonicalSchemaJSON()
            == #"{"properties":{"answer":{"type":"string"},"confidence":{"type":"number"}},"required":["answer"],"type":"object"}"#
    )
}

@Test("Chat requests decode and generate root schemas inferred from object keywords")
func chatRequestInferredRootObjectSchema() throws {
    let request = try decodeChatRequest(
        responseFormatRequestJSON(
            jsonSchema: #"{"name":"answer","schema":{"properties":{"answer":{"type":"string"}},"required":["answer"]}}"#
        )
    )

    guard case .jsonSchema(let responseSchema) = request.responseFormat else {
        Issue.record("Expected a JSON schema response format")
        return
    }
    #expect(responseSchema.schema.type == nil)
    #expect(try responseSchema.schema.resolvedType() == .object)
    #expect(try responseSchema.generationSchema().debugDescription.contains("answer"))
}

@Test("Chat requests reject explicitly scalar root response schemas")
func chatRequestExplicitScalarRootSchema() {
    expectChatValidationError(
        jsonSchemaRequestJSON(#"{"name":"answer","schema":{"type":"string"}}"#),
        parameter: "response_format.json_schema.schema.type",
        code: "invalid_field",
        message: "The root response schema must have type 'object'."
    )
}

@Test("Chat requests decode strict JSON schema response formats")
func chatRequestStrictJSONSchemaResponseFormat() throws {
    let request = try decodeChatRequest(
        responseFormatRequestJSON(
            jsonSchema: #"""
            {
              "name": "strict-answer",
              "strict": true,
              "schema": {
                "type": "object",
                "properties": {
                  "answer": {"type": "string"},
                  "metadata": {
                    "type": "object",
                    "properties": {"source": {"type": "string"}},
                    "required": ["source"],
                    "additionalProperties": false
                  }
                },
                "required": ["answer", "metadata"],
                "additionalProperties": false
              }
            }
            """#
        )
    )

    guard case .jsonSchema(let responseSchema) = request.responseFormat else {
        Issue.record("Expected a JSON schema response format")
        return
    }
    #expect(responseSchema.strict)
    #expect(responseSchema.name == "strict-answer")
}

@Test("json_object returns the migration error for json_schema")
func chatRequestRejectsJSONObjectResponseFormat() {
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_object"}}"#,
        parameter: "response_format.type",
        code: "invalid_field",
        message: "response_format type 'json_object' is not supported. Use 'json_schema' instead."
    )
}

@Test(
    "Response format wrappers reject missing, mistyped, and unknown fields",
    arguments: [
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{}}"#,
            "response_format.type",
            "missing_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":1}}"#,
            "response_format.type",
            "invalid_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"yaml"}}"#,
            "response_format.type",
            "invalid_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"text","extra":true}}"#,
            "response_format.extra",
            "unknown_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"text","json_schema":null}}"#,
            "response_format.json_schema",
            "unknown_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_schema"}}"#,
            "response_format.json_schema",
            "missing_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_schema","json_schema":null}}"#,
            "response_format.json_schema",
            "invalid_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_schema","json_schema":{"extra":true}}}"#,
            "response_format.json_schema.extra",
            "unknown_field"
        )
    ]
)
func chatRequestResponseFormatWrapperValidation(json: String, parameter: String, code: String) {
    expectChatValidationError(json, parameter: parameter, code: code)
}

@Test(
    "JSON schema response formats validate name, schema, and strict types",
    arguments: [
        (jsonSchemaRequestJSON(#"{"schema":{"type":"object"}}"#), "response_format.json_schema.name", "missing_field"),
        (jsonSchemaRequestJSON(#"{"name":1,"schema":{"type":"object"}}"#), "response_format.json_schema.name", "invalid_field"),
        (jsonSchemaRequestJSON(#"{"name":"","schema":{"type":"object"}}"#), "response_format.json_schema.name", "invalid_field"),
        (jsonSchemaRequestJSON(#"{"name":"bad name","schema":{"type":"object"}}"#), "response_format.json_schema.name", "invalid_field"),
        (
            jsonSchemaRequestJSON(
                #"""
                {
                  "name": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
                  "schema": {"type": "object"}
                }
                """#
            ),
            "response_format.json_schema.name",
            "invalid_field"
        ),
        (jsonSchemaRequestJSON(#"{"name":"answer"}"#), "response_format.json_schema.schema", "missing_field"),
        (jsonSchemaRequestJSON(#"{"name":"answer","schema":null}"#), "response_format.json_schema.schema", "invalid_field"),
        (jsonSchemaRequestJSON(#"{"name":"answer","schema":[]}"#), "response_format.json_schema.schema", "invalid_field"),
        (
            jsonSchemaRequestJSON(#"{"name":"answer","strict":null,"schema":{"type":"object"}}"#),
            "response_format.json_schema.strict",
            "invalid_field"
        )
    ]
)
func chatRequestJSONSchemaWrapperValidation(json: String, parameter: String, code: String) {
    expectChatValidationError(json, parameter: parameter, code: code)
}

@Test(
    "JSON schemas preserve precise prefixed validation paths",
    arguments: [
        (
            #"{"name":"answer","schema":{"type":"object","properties":{"answer":{"type":"string","format":"date"}}}}"#,
            "response_format.json_schema.schema.properties.answer.format",
            "unsupported_field"
        ),
        (
            #"{"name":"answer","schema":{"type":"object","properties":{"answers":{"type":"array"}}}}"#,
            "response_format.json_schema.schema.properties.answers.items",
            "invalid_field"
        ),
        (
            #"{"name":"answer","schema":{"type":"object","properties":{},"required":["missing"]}}"#,
            "response_format.json_schema.schema.required[0]",
            "invalid_field"
        ),
        (
            #"{"name":"answer","schema":{"type":"object","additionalProperties":true}}"#,
            "response_format.json_schema.schema.additionalProperties",
            "invalid_field"
        )
    ]
)
func chatRequestJSONSchemaValidationPaths(jsonSchema: String, parameter: String, code: String) {
    expectChatValidationError(
        jsonSchemaRequestJSON(jsonSchema),
        parameter: parameter,
        code: code
    )
}

@Test(
    "Strict JSON schemas require closed objects and every property",
    arguments: [
        (
            #"{"name":"answer","strict":true,"schema":{"type":"object","properties":{},"required":[]}}"#,
            "response_format.json_schema.schema.additionalProperties"
        ),
        (
            #"""
            {"name":"answer","strict":true,"schema":{
              "type":"object","properties":{"answer":{"type":"string"}},
              "required":[],"additionalProperties":false
            }}
            """#,
            "response_format.json_schema.schema.required"
        ),
        (
            #"""
            {"name":"answer","strict":true,"schema":{
              "type":"object","properties":{"metadata":{
                "type":"object","properties":{"source":{"type":"string"}},
                "required":[],"additionalProperties":false
              }},"required":["metadata"],"additionalProperties":false
            }}
            """#,
            "response_format.json_schema.schema.properties.metadata.required"
        ),
        (
            #"""
            {"name":"answer","strict":true,"schema":{
              "type":"object","properties":{"metadata":{
                "type":"object","properties":{},"required":[]
              }},"required":["metadata"],"additionalProperties":false
            }}
            """#,
            "response_format.json_schema.schema.properties.metadata.additionalProperties"
        ),
        (
            #"""
            {"name":"answer","strict":true,"schema":{
              "type":"object","properties":{"metadata":{
                "properties":{},"required":[]
              }},"required":["metadata"],"additionalProperties":false
            }}
            """#,
            "response_format.json_schema.schema.properties.metadata.additionalProperties"
        )
    ]
)
func chatRequestStrictJSONSchemaValidation(jsonSchema: String, parameter: String) {
    expectChatValidationError(
        jsonSchemaRequestJSON(jsonSchema),
        parameter: parameter,
        code: "invalid_field"
    )
}

@Test("Chat option conflicts and invalid ranges fail before generation")
func chatRequestOptionValidation() {
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"max_tokens":1,"max_completion_tokens":1}"#,
        parameter: "max_tokens",
        code: "invalid_field"
    )
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"temperature":1.1}"#,
        parameter: "temperature",
        code: "invalid_field"
    )
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"top_p":0}"#,
        parameter: "top_p",
        code: "invalid_field"
    )
}

private let validUserRequestJSON = #"{"messages":[{"role":"user","content":"Hi"}]}"#

private func responseFormatRequestJSON(jsonSchema: String) -> String {
    #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_schema","json_schema":\#(jsonSchema)}}"#
}

private func jsonSchemaRequestJSON(_ jsonSchema: String) -> String {
    responseFormatRequestJSON(jsonSchema: jsonSchema)
}

func decodeChatRequest(_ json: String) throws -> AFMChatGenerationRequest {
    try AFMChatGenerationRequest.decode(Data(json.utf8))
}

func expectChatValidationError(
    _ json: String,
    parameter: String,
    code: String,
    message: String? = nil
) {
    do {
        _ = try decodeChatRequest(json)
        Issue.record("Expected chat request validation to fail")
    } catch let error as AFMChatRequestValidationError {
        #expect(error.parameter == parameter)
        #expect(error.code == code)
        if let message {
            #expect(error.message == message)
        }
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
