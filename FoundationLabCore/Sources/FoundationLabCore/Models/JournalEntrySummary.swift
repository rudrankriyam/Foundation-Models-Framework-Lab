import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
public struct JournalEntrySummary: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    @Guide(description: "A gentle journaling prompt inspired by the user's mood, sleep, and any quote or affirmation.")
    public let prompt: String

    @Guide(description: "A short, compassionate message that acknowledges the user's mood.")
    public let upliftingMessage: String

    @Guide(description: "Short sentence starters that make it easier to begin writing.", .count(2...3))
    public let sentenceStarters: [String]

    @Guide(description: "Exactly three bullet points summarizing the entry.", .count(3...3))
    public let summaryBullets: [String]

    @Guide(description: "Themes or tags that describe the entry.", .count(3...5))
    public let themes: [String]

    public init(
        prompt: String,
        upliftingMessage: String,
        sentenceStarters: [String],
        summaryBullets: [String],
        themes: [String]
    ) {
        self.prompt = prompt
        self.upliftingMessage = upliftingMessage
        self.sentenceStarters = sentenceStarters
        self.summaryBullets = summaryBullets
        self.themes = themes
    }
}

public extension JournalEntrySummary {
    var plainTextSummary: String {
        let starters = sentenceStarters.map { "- \($0)" }.joined(separator: "\n")
        let bullets = summaryBullets.map { "- \($0)" }.joined(separator: "\n")
        let listedThemes = themes.map { "- \($0)" }.joined(separator: "\n")

        return """
        Uplifting Message:
        \(upliftingMessage)

        Prompt:
        \(prompt)

        Sentence Starters:
        \(starters)

        Summary:
        \(bullets)

        Themes:
        \(listedThemes)
        """
    }
}
