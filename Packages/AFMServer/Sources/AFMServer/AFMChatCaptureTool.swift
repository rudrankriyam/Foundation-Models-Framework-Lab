import Foundation
import FoundationModels

struct AFMChatCaptureTool: Tool {
    let name: String
    let description: String
    let parameters: GenerationSchema
    let recorder: AFMChatToolCallRecorder

    func call(arguments: GeneratedContent) async throws -> Prompt {
        await recorder.record(
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
