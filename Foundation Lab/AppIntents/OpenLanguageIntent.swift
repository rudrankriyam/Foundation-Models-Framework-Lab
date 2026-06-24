//
//  OpenLanguageIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/24/26.
//

import AppIntents

struct OpenLanguageIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Language Example"
    static let description = IntentDescription("Opens a selected language lab in Foundation Lab.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Language Example")
    var language: LanguageDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$language)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigateToLanguage(language.languageExample)
        return .result()
    }
}
