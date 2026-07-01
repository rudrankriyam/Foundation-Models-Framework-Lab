import AppIntents
import Foundation
import FoundationLabCore
import FoundationModelsKit

struct SearchMusicCatalogIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Music Catalog"
    static let description = IntentDescription(
        "Searches the music catalog for songs, albums, and artists."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Query",
        requestValueDialog: IntentDialog("What music do you want to search for?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await SearchMusicCatalogUseCase().execute(
            SearchMusicCatalogRequest(
                query: query,
                context: FoundationModelInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
