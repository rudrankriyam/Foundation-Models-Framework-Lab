import Foundation
import FoundationModelsKit

public protocol ConversationRunning: Sendable {
    func runConversation(for request: RunConversationRequest) async throws -> RunConversationResult
}
