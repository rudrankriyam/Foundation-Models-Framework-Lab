import AppIntents
import Foundation
import FoundationLabCore

struct SearchWebIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Web"
    static let description = IntentDescription(
        "Searches the web for your query and returns grounded results."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Query",
        requestValueDialog: IntentDialog("What would you like to search for?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await SearchWebUseCase().execute(
            SearchWebRequest(
                query: query,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
