import AppIntents
import Foundation
import FoundationLabCore

struct SearchContactsIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Contacts"
    static let description = IntentDescription(
        "Searches Contacts data you have authorized Foundation Lab to read."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Query",
        requestValueDialog: IntentDialog("Who do you want to search for?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await SearchContactsUseCase().execute(
            SearchContactsRequest(
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
