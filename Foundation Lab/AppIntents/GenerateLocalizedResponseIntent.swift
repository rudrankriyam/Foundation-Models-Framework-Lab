import AppIntents
import Foundation
import FoundationLabCore

struct GenerateLocalizedResponseIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Localized Response"
    static let description = IntentDescription(
        "Generates a response in a selected language supported by Foundation Models."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Language",
        requestValueDialog: IntentDialog("Which supported language should I use?")
    )
    var language: SupportedLanguageEntity

    @Parameter(
        title: "Prompt",
        requestValueDialog: IntentDialog("What should I respond to?")
    )
    var prompt: String

    @Parameter(title: "Instructions")
    var systemPrompt: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Respond to \(\.$prompt) in \(\.$language)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let localeInstruction = "Respond in \(language.displayName). Prefer natural wording for that locale."
        let trimmedSystemPrompt = systemPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
        let mergedSystemPrompt = [trimmedSystemPrompt, localeInstruction]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: "\n\n")

        let result = try await GenerateTextUseCase().execute(
            TextGenerationRequest(
                prompt: prompt,
                systemPrompt: mergedSystemPrompt.isEmpty ? nil : mergedSystemPrompt,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: result.content)
    }
}
