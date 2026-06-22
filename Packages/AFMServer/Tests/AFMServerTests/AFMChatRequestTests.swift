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
            #"{"name":"answer","schema":{"type":"string"}}"#,
            "response_format.json_schema.schema.type",
            "invalid_field"
        ),
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

@Test("Chat requests accept Apple's streaming tool sentinel and usage option")
func chatRequestAppleStreamingShape() throws {
    let request = try decodeChatRequest(
        """
        {
          "model": "system",
          "messages": [{"role": "user", "content": "Hi"}],
          "stream": true,
          "stream_options": {"include_usage": true},
          "tools": [],
          "tool_choice": "auto"
        }
        """
    )

    #expect(request.stream)
    #expect(request.streamOptions == .init(includeUsage: true))
}

@Test("Chat requests accept omitted and null tool sentinels")
func chatRequestNullToolSentinels() throws {
    let omitted = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"stream":true}"#
    )
    let null = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"stream":true,"tools":null,"tool_choice":null}"#
    )

    #expect(omitted.stream)
    #expect(null.stream)
}

@Test("Chat requests reconstruct assistant tool calls and matching tool outputs")
func chatRequestToolHistory() throws {
    let request = try decodeChatRequest(validToolHistoryJSON)
    #expect(request.messages.count == 4)
    #expect(request.messages[1].toolCalls == [
        .init(id: "call_1", name: "weather", arguments: #"{"city":"Paris"}"#)
    ])
    #expect(request.messages[2].toolCallID == "call_1")
    #expect(request.messages[2].name == "weather")
}

@Test(
    "Unsupported and unknown chat fields return precise validation errors",
    arguments: [
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function"}]}"#,
            "tools",
            "unsupported_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"tool_choice":"required"}"#,
            "tool_choice",
            "unsupported_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"stream_options":{"include_usage":true}}"#,
            "stream_options",
            "invalid_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"stream":true,"stream_options":{"extra":true}}"#,
            "stream_options.extra",
            "unknown_field"
        ),
        (#"{"messages":[{"role":"user","content":"Hi"}],"surprise":1}"#, "surprise", "unknown_field"),
        (
            #"{"messages":[{"role":"user","content":[{"type":"image_url","image_url":{"url":"x"}}]}]}"#,
            "messages[0].content[0].image_url",
            "unsupported_field"
        )
    ]
)
func chatRequestRejectedFields(json: String, parameter: String, code: String) {
    expectChatValidationError(json, parameter: parameter, code: code)
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

@Test("Tool history rejects missing, duplicate, and out-of-order outputs")
func chatRequestToolSequenceValidation() {
    expectChatValidationError(
        #"""
        {"messages":[
          {"role":"assistant","tool_calls":[
            {"id":"a","type":"function","function":{"name":"f","arguments":"{}"}}
          ]},
          {"role":"user","content":"continue"}
        ]}
        """#,
        parameter: "messages[1].role",
        code: "invalid_field"
    )
    expectChatValidationError(
        #"{"messages":[{"role":"tool","tool_call_id":"missing","content":"x"}]}"#,
        parameter: "messages[0].tool_call_id",
        code: "invalid_field"
    )
    expectChatValidationError(
        #"""
        {"messages":[
          {"role":"assistant","tool_calls":[
            {"id":"a","type":"function","function":{"name":"f","arguments":"{}"}},
            {"id":"a","type":"function","function":{"name":"f","arguments":"{}"}}
          ]},
          {"role":"tool","tool_call_id":"a","content":"x"}
        ]}
        """#,
        parameter: "messages[0].tool_calls[1].id",
        code: "invalid_field"
    )
}

private let validToolHistoryJSON = #"""
{
  "messages": [
    {"role":"user","content":"Weather?"},
    {"role":"assistant","tool_calls":[
      {"id":"call_1","type":"function","function":{"name":"weather","arguments":"{\"city\":\"Paris\"}"}}
    ]},
    {"role":"tool","tool_call_id":"call_1","name":"weather","content":"Sunny"},
    {"role":"user","content":"Summarize"}
  ]
}
"""#

private let validUserRequestJSON = #"{"messages":[{"role":"user","content":"Hi"}]}"#

private func responseFormatRequestJSON(jsonSchema: String) -> String {
    #"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"json_schema","json_schema":\#(jsonSchema)}}"#
}

private func jsonSchemaRequestJSON(_ jsonSchema: String) -> String {
    responseFormatRequestJSON(jsonSchema: jsonSchema)
}

private func decodeChatRequest(_ json: String) throws -> AFMChatGenerationRequest {
    try AFMChatGenerationRequest.decode(Data(json.utf8))
}

private func expectChatValidationError(
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
