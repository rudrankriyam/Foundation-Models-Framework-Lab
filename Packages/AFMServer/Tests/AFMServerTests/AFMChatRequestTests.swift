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

@Test("Chat requests decode validated function tools and OpenAI tool choices")
func chatRequestFunctionTools() throws {
    let request = try decodeChatRequest(
        #"""
        {
          "messages": [{"role":"user","content":"Weather?"}],
          "tools": [{
            "type": "function",
            "function": {
              "name": "get_weather",
              "description": "Get weather without executing it locally.",
              "strict": true,
              "parameters": {
                "type": "object",
                "properties": {
                  "city": {"type":"string"},
                  "days": {"type":"integer"},
                  "units": {"type":"string","enum":["metric","imperial"]}
                },
                "required": ["city", "days", "units"],
                "additionalProperties": false
              }
            }
          }],
          "tool_choice": "auto",
          "parallel_tool_calls": true
        }
        """#
    )

    #expect(request.tools.count == 1)
    #expect(request.tools[0].name == "get_weather")
    #expect(request.tools[0].strict == true)
    #expect(request.tools[0].parameters.required == ["city", "days", "units"])
    #expect(request.toolChoice == .auto)
    #expect(request.parallelToolCalls)
}

@Test("Tool choice defaults follow the OpenAI request shape")
func chatRequestToolChoiceDefaults() throws {
    let withoutTools = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}]}"#
    )
    let withTools = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{"name":"ping"}}]}"#
    )
    let disabled = try decodeChatRequest(
        #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{"name":"ping"}}],"tool_choice":"none"}"#
    )
    let disabledParallelism = try decodeChatRequest(
        #"""
        {"messages":[{"role":"user","content":"Hi"}],
         "tools":[{"type":"function","function":{"name":"ping"}}],
         "tool_choice":"none","parallel_tool_calls":false}
        """#
    )

    #expect(withoutTools.toolChoice == .none)
    #expect(withTools.toolChoice == .auto)
    #expect(disabled.toolChoice == .none)
    #expect(disabled.tools.count == 1)
    #expect(!disabledParallelism.parallelToolCalls)
}

#if compiler(>=6.4)
@Test("Named tool choices decode when the public OS 27 required mode is available")
func chatRequestNamedToolChoiceOnOS27() throws {
    guard #available(macOS 27.0, *) else { return }
    let request = try decodeChatRequest(
        #"""
        {"messages":[{"role":"user","content":"Hi"}],
         "tools":[{"type":"function","function":{"name":"ping"}}],
         "tool_choice":{"type":"function","function":{"name":"ping"}}}
        """#
    )
    #expect(request.toolChoice == .function(name: "ping"))
}
#endif

@Test(
    "Strict tool schemas require closed objects and required properties recursively",
    arguments: [
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{
              "name":"ping","strict":true,
              "parameters":{"type":"object","properties":{},"required":[]}
            }}]}
            """#,
            "tools[0].function.parameters.additionalProperties"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{
              "name":"ping","strict":true,
              "parameters":{"type":"object","properties":{"value":{"type":"string"}},
              "required":[],"additionalProperties":false}
            }}]}
            """#,
            "tools[0].function.parameters.required"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{
              "name":"ping","strict":true,
              "parameters":{"type":"object","properties":{"nested":{"type":"object","properties":{},"required":[]}},
              "required":["nested"],"additionalProperties":false}
            }}]}
            """#,
            "tools[0].function.parameters.properties.nested.additionalProperties"
        )
    ]
)
func chatRequestStrictToolSchemas(json: String, parameter: String) {
    expectChatValidationError(json, parameter: parameter, code: "invalid_tool_schema")
}

@Test("Non-strict tools may use optional properties from the supported schema subset")
func chatRequestNonStrictOptionalProperties() throws {
    let request = try decodeChatRequest(
        #"""
        {"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{
          "name":"ping","strict":false,
          "parameters":{"type":"object","properties":{"value":{"type":"string"}}}
        }}]}
        """#
    )
    #expect(request.tools[0].strict == false)
    #expect(request.tools[0].parameters.required == nil)
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
            "tools[0].function",
            "missing_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"tool_choice":"required"}"#,
            "tool_choice",
            "invalid_field"
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
        (#"{"messages":[{"role":"user","content":"Hi"}],"response_format":{}}"#, "response_format", "unsupported_field"),
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

@Test(
    "Invalid tool declarations return precise field and schema errors",
    arguments: [
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"computer","function":{"name":"ping"}}]}"#,
            "tools[0].type",
            "invalid_field"
        ),
        (
            #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{"name":"bad name"}}]}"#,
            "tools[0].function.name",
            "invalid_field"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{
              "type":"function","function":{"name":"ping","parameters":{"type":"object","patternProperties":{}}}
            }]}
            """#,
            "tools[0].function.parameters.patternProperties",
            "unsupported_schema_keyword"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{
              "type":"function","function":{"name":"ping","parameters":{"type":"array","items":{"type":"string"}}}
            }]}
            """#,
            "tools[0].function.parameters.type",
            "invalid_tool_schema"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[{
              "type":"function","function":{"name":"ping","parameters":{"type":"object","additionalProperties":true}}
            }]}
            """#,
            "tools[0].function.parameters.additionalProperties",
            "invalid_tool_schema"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],"tools":[
              {"type":"function","function":{"name":"ping"}},
              {"type":"function","function":{"name":"ping"}}
            ]}
            """#,
            "tools[1].function.name",
            "invalid_field"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],
             "tools":[{"type":"function","function":{"name":"ping"}}],
             "tool_choice":{"type":"function","function":{"name":"missing"}}}
            """#,
            "tool_choice.function.name",
            "invalid_field"
        ),
        (
            #"""
            {"messages":[{"role":"user","content":"Hi"}],
             "tools":[{"type":"function","function":{"name":"ping"}}],
             "parallel_tool_calls":false}
            """#,
            "parallel_tool_calls",
            "unsupported_field"
        )
    ]
)
func chatRequestInvalidTools(json: String, parameter: String, code: String) {
    expectChatValidationError(json, parameter: parameter, code: code)
}

@Test("Tool definition and schema limits fail before generation")
func chatRequestToolLimits() throws {
    let tools = (0...AFMChatToolLimits.maximumDefinitions).map { index in
        #"{"type":"function","function":{"name":"tool_\#(index)"}}"#
    }.joined(separator: ",")
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"tools":[\#(tools)]}"#,
        parameter: "tools",
        code: "invalid_field"
    )

    let oversizedDescription = String(repeating: "x", count: AFMChatToolLimits.maximumSchemaBytes)
    let schema = ##"{"type":"object","description":"\##(oversizedDescription)"}"##
    expectChatValidationError(
        #"{"messages":[{"role":"user","content":"Hi"}],"tools":[{"type":"function","function":{"name":"ping","parameters":\#(schema)}}]}"#,
        parameter: "tools[0].function.parameters",
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

private func decodeChatRequest(_ json: String) throws -> AFMChatGenerationRequest {
    try AFMChatGenerationRequest.decode(Data(json.utf8))
}

private func expectChatValidationError(_ json: String, parameter: String, code: String) {
    do {
        _ = try decodeChatRequest(json)
        Issue.record("Expected chat request validation to fail")
    } catch let error as AFMChatRequestValidationError {
        #expect(error.parameter == parameter)
        #expect(error.code == code)
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
