import Foundation
import FoundationModels
import Testing
@testable import AFMServer

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, *)
@Test("Modern session errors distinguish concurrency from transcript mutation")
func modernSessionErrorMapping() {
    let concurrent = AFMFoundationModelsChatGenerator.mapModernError(
        LanguageModelSession.Error.concurrentRequests
    )
    let transcriptMutation = AFMFoundationModelsChatGenerator.mapModernError(
        LanguageModelSession.Error.transcriptMutationWhileResponding
    )

    #expect(concurrent == .concurrentRequest)
    #expect(transcriptMutation == nil)
}
#endif

@Test("Transcript reconstruction preserves instructions, turns, tools, and the active prompt")
func transcriptReconstruction() throws {
    let request = try AFMChatGenerationRequest.decode(Data(transcriptRequestJSON.utf8))
    let prepared = try AFMChatTranscriptBuilder.prepare(request)
    let entries = Array(prepared.transcript)

    #expect(entries.count == 5)
    guard case .instructions(let instructions) = entries[0] else {
        Issue.record("Expected instructions entry")
        return
    }
    #expect(text(instructions.segments) == ["System rules", "Developer rules"])

    guard case .prompt(let historicalPrompt) = entries[1] else {
        Issue.record("Expected historical prompt")
        return
    }
    #expect(text(historicalPrompt.segments) == ["Question"])

    guard case .response(let response) = entries[2] else {
        Issue.record("Expected assistant response")
        return
    }
    #expect(text(response.segments) == ["Checking"])

    guard case .toolCalls(let calls) = entries[3] else {
        Issue.record("Expected tool calls")
        return
    }
    #expect(calls.first?.id == "call_1")
    #expect(calls.first?.toolName == "weather")
    let argumentsJSON = try #require(calls.first?.arguments.jsonString)
    let arguments = try #require(
        JSONSerialization.jsonObject(with: Data(argumentsJSON.utf8)) as? [String: String]
    )
    #expect(arguments == ["city": "Paris"])

    guard case .toolOutput(let output) = entries[4] else {
        Issue.record("Expected tool output")
        return
    }
    #expect(output.id == "call_1")
    #expect(output.toolName == "weather")
    #expect(text(output.segments) == ["Sunny"])

    let inputEntries = Array(prepared.inputTranscript)
    guard case .prompt(let activePrompt) = inputEntries.last else {
        Issue.record("Expected active prompt")
        return
    }
    #expect(text(activePrompt.segments) == ["Final", "question"])
}

@Test("A final tool output remains in history and receives an empty continuation prompt")
func finalToolOutputReconstruction() throws {
    let request = try AFMChatGenerationRequest.decode(Data(finalToolRequestJSON.utf8))
    let prepared = try AFMChatTranscriptBuilder.prepare(request)
    let entries = Array(prepared.transcript)

    guard case .toolOutput = entries.last else {
        Issue.record("Expected the final tool output in the reconstructed transcript")
        return
    }
    guard case .prompt(let activePrompt) = Array(prepared.inputTranscript).last else {
        Issue.record("Expected the continuation prompt")
        return
    }
    #expect(text(activePrompt.segments) == [""])
}

@Test("Structured response formats reach generation and transcript token accounting")
func structuredResponseFormatPreparation() throws {
    let request = try AFMChatGenerationRequest.decode(Data(structuredRequestJSON.utf8))
    let prepared = try AFMChatTranscriptBuilder.prepare(request)

    #expect(prepared.responseSchema?.name == "person")
    #expect(prepared.responseSchema?.fallbackTokenText.contains("Structured person guidance") == true)
    guard case .prompt(let activePrompt) = Array(prepared.inputTranscript).last else {
        Issue.record("Expected the active structured prompt")
        return
    }
    #expect(activePrompt.responseFormat != nil)
}

@Test("Tools and structured response formats survive request preparation together")
func toolAndStructuredResponseFormatPreparation() throws {
    let request = try AFMChatGenerationRequest.decode(Data(toolAndStructuredRequestJSON.utf8))

    #expect(request.tools.map(\.name) == ["lookup_weather"])
    #expect(request.toolChoice == .auto)
    guard case .jsonSchema(let responseFormat) = request.responseFormat else {
        Issue.record("Expected a JSON schema response format")
        return
    }
    #expect(responseFormat.name == "weather_report")

    let toolRuntime = try AFMChatToolRuntime(request: request)
    #expect(toolRuntime.tools.map(\.name) == ["lookup_weather"])
    let prepared = try AFMChatTranscriptBuilder.prepare(
        request,
        toolDefinitions: toolRuntime.transcriptDefinitions
    )

    #expect(prepared.responseSchema?.name == "weather_report")
    let inputEntries = Array(prepared.inputTranscript)
    guard case .instructions(let instructions) = inputEntries.first else {
        Issue.record("Expected active tool definitions in the input transcript")
        return
    }
    #expect(instructions.toolDefinitions.map(\.name) == ["lookup_weather"])
    guard case .prompt(let activePrompt) = inputEntries.last else {
        Issue.record("Expected the active structured prompt")
        return
    }
    #expect(activePrompt.responseFormat != nil)
}

@Test("Text response formats keep schema guidance out of the transcript")
func textResponseFormatPreparation() throws {
    let request = try AFMChatGenerationRequest.decode(
        Data(#"{"messages":[{"role":"user","content":"Hi"}],"response_format":{"type":"text"}}"#.utf8)
    )
    let prepared = try AFMChatTranscriptBuilder.prepare(request)

    #expect(prepared.responseSchema == nil)
    guard case .prompt(let activePrompt) = Array(prepared.inputTranscript).last else {
        Issue.record("Expected the active text prompt")
        return
    }
    #expect(activePrompt.responseFormat == nil)
}

private func text(_ segments: [Transcript.Segment]) -> [String] {
    segments.compactMap { segment in
        guard case .text(let text) = segment else { return nil }
        return text.content
    }
}

private let transcriptRequestJSON = #"""
{
  "messages": [
    {"role":"system","content":"System rules"},
    {"role":"developer","content":"Developer rules"},
    {"role":"user","content":"Question"},
    {"role":"assistant","content":"Checking","tool_calls":[
      {"id":"call_1","type":"function","function":{"name":"weather","arguments":"{\"city\":\"Paris\"}"}}
    ]},
    {"role":"tool","tool_call_id":"call_1","name":"weather","content":"Sunny"},
    {"role":"user","content":[{"type":"text","text":"Final"},{"type":"text","text":"question"}]}
  ]
}
"""#

private let finalToolRequestJSON = #"""
{
  "messages": [
    {"role":"user","content":"Question"},
    {"role":"assistant","tool_calls":[
      {"id":"call_1","type":"function","function":{"name":"weather","arguments":"{}"}}
    ]},
    {"role":"tool","tool_call_id":"call_1","content":"Sunny"}
  ]
}
"""#

private let structuredRequestJSON = #"""
{
  "messages": [{"role":"user","content":"Ada Lovelace"}],
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "person",
      "description": "Structured person guidance",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {"name": {"type": "string"}},
        "required": ["name"],
        "additionalProperties": false
      }
    }
  }
}
"""#

private let toolAndStructuredRequestJSON = #"""
{
  "messages": [{"role": "user", "content": "Plan for Paris"}],
  "tools": [{
    "type": "function",
    "function": {
      "name": "lookup_weather",
      "description": "Look up the weather for a city.",
      "strict": true,
      "parameters": {
        "type": "object",
        "properties": {"city": {"type": "string"}},
        "required": ["city"],
        "additionalProperties": false
      }
    }
  }],
  "tool_choice": "auto",
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "weather_report",
      "strict": true,
      "schema": {
        "type": "object",
        "properties": {"summary": {"type": "string"}},
        "required": ["summary"],
        "additionalProperties": false
      }
    }
  }
}
"""#
