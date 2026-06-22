import Foundation
import FoundationModels
import FoundationModelsKit
import Testing
@testable import AFMServer

@Test("Capture tools report canonical calls in invocation order without executing a registry")
func captureToolReportsCalls() async throws {
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Use both tools"])],
        tools: [
            toolDefinition(name: "first_tool"),
            toolDefinition(name: "second_tool")
        ]
    )
    let runtime = try AFMChatToolRuntime(request: request)
    let first = try #require(runtime.tools[0] as? AFMChatCaptureTool)
    let second = try #require(runtime.tools[1] as? AFMChatCaptureTool)

    await invoke(second, arguments: #"{"z":2,"a":"second"}"#)
    await invoke(first, arguments: #"{"z":1,"a":"z-last"}"#)
    await invoke(first, arguments: #"{"z":3,"a":"a-first"}"#)

    let calls = try await runtime.capturedCalls()
    #expect(calls.map(\.name) == ["second_tool", "first_tool", "first_tool"])
    #expect(calls.map(\.arguments) == [
        #"{"a":"second","z":2}"#,
        #"{"a":"z-last","z":1}"#,
        #"{"a":"a-first","z":3}"#
    ])
    #expect(Set(calls.map(\.id)).count == 3)
    #expect(calls.allSatisfy { $0.id.hasPrefix("call_") })
}

@Test("Tool call capture enforces its hard count limit")
func captureToolCallLimit() async throws {
    let request = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Use a tool"])],
        tools: [toolDefinition(name: "ping")]
    )
    let runtime = try AFMChatToolRuntime(request: request)
    let tool = try #require(runtime.tools[0] as? AFMChatCaptureTool)

    for index in 0...AFMChatToolLimits.maximumCapturedCalls {
        await invoke(tool, arguments: #"{"value":\#(index)}"#)
    }

    do {
        _ = try await runtime.capturedCalls()
        Issue.record("Expected the captured-call limit to fail")
    } catch let error as AFMChatGenerationError {
        #expect(error == .toolCallLimitExceeded)
    }
}

@Test("Input token accounting includes active tool definitions only")
func toolDefinitionsInInputTranscript() throws {
    let enabled = AFMChatGenerationRequest(
        messages: [.init(role: .user, contentSegments: ["Hello"])],
        tools: [toolDefinition(name: "ping")]
    )
    let enabledRuntime = try AFMChatToolRuntime(request: enabled)
    let enabledPrepared = try AFMChatTranscriptBuilder.prepare(
        enabled,
        toolDefinitions: enabledRuntime.transcriptDefinitions
    )

    guard case .instructions(let instructions) = Array(enabledPrepared.inputTranscript).first else {
        Issue.record("Expected synthetic tool instructions in counted input")
        return
    }
    #expect(instructions.toolDefinitions.map(\.name) == ["ping"])
    #expect(Array(enabledPrepared.transcript).isEmpty)

    let disabled = AFMChatGenerationRequest(
        messages: enabled.messages,
        tools: enabled.tools,
        toolChoice: .none
    )
    let disabledRuntime = try AFMChatToolRuntime(request: disabled)
    let disabledPrepared = try AFMChatTranscriptBuilder.prepare(
        disabled,
        toolDefinitions: disabledRuntime.transcriptDefinitions
    )
    guard case .prompt = Array(disabledPrepared.inputTranscript).first else {
        Issue.record("Disabled tools must not contribute counted definitions")
        return
    }
    #expect(disabledRuntime.tools.isEmpty)
}

private func toolDefinition(name: String) -> AFMChatToolDefinition {
    .init(
        name: name,
        description: "Report arguments only.",
        parameters: .init(
            type: "object",
            properties: [
                "a": .init(type: "string"),
                "z": .init(type: "integer")
            ],
            additionalProperties: false
        )
    )
}

private func invoke(_ tool: AFMChatCaptureTool, arguments: String) async {
    do {
        _ = try await tool.call(arguments: try GeneratedContent(json: arguments))
        Issue.record("Capture tools must stop generation instead of returning output")
    } catch {
        // The capture sentinel is the expected stop boundary.
    }
}
