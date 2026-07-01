import AppIntents
import Foundation
import FoundationLabCore
import FoundationModelsKit

struct GetCurrentLocationIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Current Location"
    static let description = IntentDescription(
        "Returns your current location after you grant permission."
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await GetCurrentLocationUseCase().execute(
            GetCurrentLocationRequest(
                context: FoundationModelInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
