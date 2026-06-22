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
        let selectedDefinitions: [(offset: Int, element: AFMChatToolDefinition)]
        switch request.toolChoice {
        case .none:
            selectedDefinitions = []
        case .auto, .required:
            selectedDefinitions = Array(request.tools.enumerated())
        case .function(let name):
            selectedDefinitions = request.tools.enumerated().filter { $0.element.name == name }
        }

        let recorder = AFMChatToolCallRecorder()
        let captureTools = try selectedDefinitions.map { index, definition in
            AFMChatCaptureTool(
                name: definition.name,
                description: definition.description,
                parameters: try definition.parameters.generationSchema(
                    rootName: "\(definition.name)Arguments"
                ),
                definitionIndex: index,
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
        let sortedCalls = snapshot.calls.sorted { left, right in
            if left.definitionIndex != right.definitionIndex {
                return left.definitionIndex < right.definitionIndex
            }
            if left.arguments != right.arguments {
                return left.arguments < right.arguments
            }
            return left.sequence < right.sequence
        }
        return sortedCalls.map { call in
            AFMChatToolCall(
                id: "call_\(UUID().uuidString)",
                name: call.name,
                arguments: call.arguments
            )
        }
    }
}
