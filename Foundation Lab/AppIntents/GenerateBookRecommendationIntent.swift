//
//  GenerateBookRecommendationIntent.swift
//  FoundationLab
//
//  Created by Codex on 3/15/26.
//

import AppIntents
import Foundation
import FoundationLabCore

struct GenerateBookRecommendationIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Book Recommendation"
    static let description = IntentDescription(
        "Creates a structured book recommendation from your prompt."
    )
    static let openAppWhenRun = false

    @Parameter(
        title: "Prompt",
        requestValueDialog: IntentDialog("What kind of book recommendation would you like?")
    )
    var prompt: String

    @Parameter(title: "Instructions")
    var systemPrompt: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Generate a book recommendation for \(\.$prompt)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let response = try await GenerateBookRecommendationUseCase().execute(
            GenerateBookRecommendationRequest(
                prompt: prompt,
                systemPrompt: systemPrompt,
                context: CapabilityInvocationContext(
                    source: .appIntent,
                    localeIdentifier: Locale.current.identifier
                )
            )
        )

        return .result(value: response.recommendation.plainTextSummary)
    }
}
