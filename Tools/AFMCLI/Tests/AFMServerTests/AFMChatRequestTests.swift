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
        (#"{"messages":[{"role":"user","content":"Hi"}],"stream":true}"#, "stream", "unsupported_field"),
        (#"{"messages":[{"role":"user","content":"Hi"}],"tools":[]}"#, "tools", "unsupported_field"),
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
