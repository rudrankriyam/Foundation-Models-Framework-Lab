import Foundation

public struct AFMChatStreamOptions: Sendable, Equatable {
    public let includeUsage: Bool

    public init(includeUsage: Bool = false) {
        self.includeUsage = includeUsage
    }
}

extension AFMChatStreamOptions: Decodable {
    private static let allowedFields: Set<String> = ["include_usage"]

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: AFMJSONKey.self)
        try rejectUnknownFields(in: container, allowed: Self.allowedFields, decoder: decoder)
        includeUsage = try container.decodeIfPresent(Bool.self, forKey: .init("include_usage")) ?? false
    }
}
