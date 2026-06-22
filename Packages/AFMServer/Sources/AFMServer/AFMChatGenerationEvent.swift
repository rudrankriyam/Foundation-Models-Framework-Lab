import Foundation

public enum AFMChatGenerationEvent: Sendable, Equatable {
    case contentDelta(String)
}
