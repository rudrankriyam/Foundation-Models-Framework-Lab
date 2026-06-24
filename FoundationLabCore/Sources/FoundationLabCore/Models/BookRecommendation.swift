import Foundation
import FoundationModels
import FoundationModelsKit

@Generable
public struct BookRecommendation: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    @Guide(description: "The title of the book")
    public let title: String

    @Guide(description: "The author's name")
    public let author: String

    @Guide(description: "A brief description in 2-3 sentences")
    public let description: String

    @Guide(description: "Genre of the book")
    public let genre: BookGenre

    public init(
        title: String,
        author: String,
        description: String,
        genre: BookGenre
    ) {
        self.title = title
        self.author = author
        self.description = description
        self.genre = genre
    }
}

@Generable
public enum BookGenre: RuntimeCompatibleGenerable, Sendable, Hashable, Codable {
    case fiction
    case nonFiction
    case mystery
    case romance
    case sciFi
    case fantasy
    case biography
    case history
}

public extension BookRecommendation {
    var plainTextSummary: String {
        """
        Title: \(title)
        Author: \(author)
        Genre: \(genre.displayName)

        Description:
        \(description)
        """
    }
}

public extension BookGenre {
    var displayName: String {
        switch self {
        case .fiction:
            return "Fiction"
        case .nonFiction:
            return "Non-Fiction"
        case .mystery:
            return "Mystery"
        case .romance:
            return "Romance"
        case .sciFi:
            return "Sci-Fi"
        case .fantasy:
            return "Fantasy"
        case .biography:
            return "Biography"
        case .history:
            return "History"
        }
    }
}
