import Foundation
import FoundationModelsKit

/// A captured piece of the model context used for an experiment run.
public struct FoundationLabExperimentEvent: Codable, Hashable, Identifiable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case id
        case role
        case kind
        case text
        case toolName
        case timestamp
    }

    public enum Role: String, Codable, Hashable, Sendable {
        case system
        case user
        case assistant
        case tool
    }

    public enum Kind: String, Codable, Hashable, Sendable {
        case message
        case toolCall
        case toolResult
    }

    public let id: UUID
    public let role: Role
    public let kind: Kind
    public let text: String
    public let toolName: String?
    public let timestamp: Date?

    public init(
        id: UUID = UUID(),
        role: Role,
        kind: Kind = .message,
        text: String,
        toolName: String? = nil,
        timestamp: Date? = nil
    ) {
        self.id = id
        self.role = role
        self.kind = kind
        self.text = text
        self.toolName = toolName
        self.timestamp = timestamp
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: (try? container.decode(UUID.self, forKey: .id)) ?? UUID(),
            role: (try? container.decode(Role.self, forKey: .role)) ?? .system,
            kind: (try? container.decode(Kind.self, forKey: .kind)) ?? .message,
            text: (try? container.decode(String.self, forKey: .text)) ?? "",
            toolName: try? container.decode(String.self, forKey: .toolName),
            timestamp: try? container.decode(Date.self, forKey: .timestamp)
        )
    }
}
