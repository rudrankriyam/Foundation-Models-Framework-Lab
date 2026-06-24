import AppIntents
import Foundation
import FoundationLabCore

struct GenerateWebPageSummaryIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Web Page Summary"
    static let description = IntentDescription(
        "Summarizes the metadata available for a web page."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "URL",
        requestValueDialog: IntentDialog("Which web page do you want to summarize?")
    )
    var url: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await GenerateWebPageSummaryUseCase().execute(
            GenerateWebPageSummaryRequest(
                url: url,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
