import Foundation
import FoundationModels

struct AFMChatCaptureTool: Tool {
    let name: String
    let description: String
    let parameters: GenerationSchema
    let definitionIndex: Int
    let recorder: AFMChatToolCallRecorder

    func call(arguments: GeneratedContent) async throws -> Prompt {
        await recorder.record(
            definitionIndex: definitionIndex,
            name: name,
            arguments: arguments.jsonString
        )
        throw AFMChatToolCaptureSignal()
    }
}

private struct AFMChatToolCaptureSignal: Error {}

extension LanguageModelSession.ToolCallError {
    var isAFMChatToolCapture: Bool {
        underlyingError is AFMChatToolCaptureSignal
    }
}
