import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
public struct FoundationLabConversationSummary: RuntimeCompatibleGenerable, Sendable {
    @Guide(
        description:
            "A comprehensive summary of the conversation including the important context needed to continue it."
    )
    public let summary: String

    @Guide(description: "The key topics, themes, or tasks discussed in the conversation.")
    public let keyTopics: [String]

    @Guide(description: "User preferences, goals, or requests that should carry into future turns.")
    public let userPreferences: [String]

    public init(
        summary: String,
        keyTopics: [String],
        userPreferences: [String]
    ) {
        self.summary = summary
        self.keyTopics = keyTopics
        self.userPreferences = userPreferences
    }
}
