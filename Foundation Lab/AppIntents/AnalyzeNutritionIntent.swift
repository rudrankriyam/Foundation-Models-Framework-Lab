import AppIntents
import Foundation
import FoundationLabCore

struct AnalyzeNutritionIntent: AppIntent {
    static let title: LocalizedStringResource = "Estimate Meal Nutrition"
    static let description = IntentDescription(
        "Generates an approximate nutrition summary from a meal description."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Meal Description",
        requestValueDialog: IntentDialog("What meal should I estimate?")
    )
    var mealDescription: String

    @Parameter(title: "Response Language")
    var responseLanguage: String?

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let trimmedResponseLanguage = responseLanguage?.trimmingCharacters(in: .whitespacesAndNewlines)
        let response = try await AnalyzeNutritionUseCase().execute(
            AnalyzeNutritionRequest(
                foodDescription: mealDescription,
                responseLanguage: trimmedResponseLanguage?.isEmpty == false ? trimmedResponseLanguage! : "English",
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.analysis.insights)
    }
}
