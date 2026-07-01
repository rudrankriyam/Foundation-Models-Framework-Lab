import AppIntents
import Foundation
import FoundationLabCore
import FoundationModelsKit

struct GetWeatherIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weather"
    static let description = IntentDescription(
        "Looks up current weather for a location."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Location",
        requestValueDialog: IntentDialog("Which location do you want weather information for?")
    )
    var location: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await GetWeatherUseCase().execute(
            GetWeatherRequest(
                location: location,
                context: FoundationModelInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
