import Foundation
import FoundationModelsKit

public struct RunConversationUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.run-conversation",
        displayName: "Run Conversation",
        summary: "Runs a sequence of prompts through one shared Foundation Models session."
    )

    private let runner: any ConversationRunning

    public init(runner: any ConversationRunning = FoundationModelsConversationRunner()) {
        self.runner = runner
    }

    public func execute(_ request: RunConversationRequest) async throws -> RunConversationResult {
        let prompts = request.prompts.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard prompts.contains(where: { !$0.isEmpty }) else {
            throw FoundationLabCoreError.invalidRequest("Missing prompts")
        }

        return try await runner.runConversation(for: request)
    }
}
