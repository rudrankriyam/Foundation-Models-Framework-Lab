import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
public struct StoryOutline: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    @Guide(description: "The title of the story")
    public let title: String

    @Guide(description: "Main character name and brief description")
    public let protagonist: String

    @Guide(description: "The central conflict or challenge")
    public let conflict: String

    @Guide(description: "The setting where the story takes place")
    public let setting: String

    @Guide(description: "Story genre")
    public let genre: StoryGenre

    @Guide(description: "Major themes explored in the story")
    public let themes: [String]

    public init(
        title: String,
        protagonist: String,
        conflict: String,
        setting: String,
        genre: StoryGenre,
        themes: [String]
    ) {
        self.title = title
        self.protagonist = protagonist
        self.conflict = conflict
        self.setting = setting
        self.genre = genre
        self.themes = themes
    }
}

@Generable
public enum StoryGenre: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    case adventure
    case mystery
    case romance
    case thriller
    case fantasy
    case sciFi
    case horror
    case comedy
}

public extension StoryOutline {
    var plainTextSummary: String {
        """
        Title: \(title)

        Genre: \(genre.displayName)

        Protagonist:
        \(protagonist)

        Central Conflict:
        \(conflict)

        Setting:
        \(setting)

        Major Themes:
        \(themes.map { "• \($0)" }.joined(separator: "\n"))
        """
    }
}

public extension StoryGenre {
    var displayName: String {
        switch self {
        case .adventure:
            return "Adventure"
        case .mystery:
            return "Mystery"
        case .romance:
            return "Romance"
        case .thriller:
            return "Thriller"
        case .fantasy:
            return "Fantasy"
        case .sciFi:
            return "Sci-Fi"
        case .horror:
            return "Horror"
        case .comedy:
            return "Comedy"
        }
    }
}
