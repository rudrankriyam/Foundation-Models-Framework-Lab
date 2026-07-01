import AppIntents
import Foundation
import FoundationLabCore
import FoundationModelsKit

struct ManageRemindersIntent: AppIntent {
    static let title: LocalizedStringResource = "Manage Reminders"
    static let description = IntentDescription(
        "Creates or updates reminders after you approve the change."
    )
    static let openAppWhenRun = true

    @Parameter(
        title: "Request",
        requestValueDialog: IntentDialog("What would you like to do with reminders?")
    )
    var prompt: String

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await ManageRemindersUseCase().execute(
            ManageRemindersRequest(
                mode: .customPrompt,
                customPrompt: prompt,
                referenceDate: .now,
                timeZoneIdentifier: TimeZone.current.identifier,
                context: FoundationModelInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.content)
    }
}
