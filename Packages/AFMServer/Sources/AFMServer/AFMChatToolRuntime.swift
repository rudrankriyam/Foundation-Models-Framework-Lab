import Foundation
import FoundationModels
import FoundationModelsKit

struct AFMChatToolRuntime {
    let tools: [any Tool]
    let transcriptDefinitions: [Transcript.ToolDefinition]
    private let recorder: AFMChatToolCallRecorder

    var isActive: Bool {
        !tools.isEmpty
    }

    init(request: AFMChatGenerationRequest) throws {
        let selectedDefinitions: [AFMChatToolDefinition]
        switch request.toolChoice {
        case .none:
            selectedDefinitions = []
        case .auto, .required:
            selectedDefinitions = request.tools
        case .function(let name):
            selectedDefinitions = request.tools.filter { $0.name == name }
        }

        let recorder = AFMChatToolCallRecorder()
        let captureTools = try selectedDefinitions.map { definition in
            AFMChatCaptureTool(
                name: definition.name,
                description: definition.description,
                parameters: try definition.parameters.generationSchema(
                    rootName: "\(definition.name)Arguments"
                ),
                recorder: recorder
            )
        }
        self.recorder = recorder
        tools = captureTools
        transcriptDefinitions = captureTools.map {
            Transcript.ToolDefinition(
                name: $0.name,
                description: $0.description,
                parameters: $0.parameters
            )
        }
    }

    func capturedCalls() async throws -> [AFMChatToolCall] {
        let snapshot = await recorder.snapshot()
        guard !snapshot.exceededLimit else {
            throw AFMChatGenerationError.toolCallLimitExceeded
        }
        guard !snapshot.invalidArguments else {
            throw AFMChatGenerationError.unsupportedInput
        }
        let orderedCalls = snapshot.calls.sorted { $0.sequence < $1.sequence }
        return orderedCalls.map { call in
            AFMChatToolCall(
                id: "call_\(UUID().uuidString)",
                name: call.name,
                arguments: call.arguments
            )
        }
    }
}
