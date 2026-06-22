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
