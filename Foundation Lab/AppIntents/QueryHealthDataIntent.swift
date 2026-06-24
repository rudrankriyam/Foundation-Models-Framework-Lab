import AppIntents
import Foundation
import FoundationLabCore

struct QueryHealthDataIntent: AppIntent {
    static let title: LocalizedStringResource = "Read Health Data"
    static let description = IntentDescription(
        "Answers a question using Health data you have authorized Foundation Lab to read."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Request",
        requestValueDialog: IntentDialog("What do you want to know about your available Health data?")
    )
    var query: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await QueryHealthDataUseCase().execute(
            QueryHealthDataRequest(
                query: query,
                systemPrompt: """
                Use only measurements returned by the Health tool. Never invent missing values, trends, goals,
                correlations, diagnoses, or predictions. State unavailable data plainly. Do not provide medical advice.
                """,
                referenceDate: .now,
                timeZoneIdentifier: TimeZone.current.identifier,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
