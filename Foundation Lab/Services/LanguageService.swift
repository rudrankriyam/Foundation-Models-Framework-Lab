//
//  LanguageService.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationLabCore
import FoundationModelsKit

@MainActor
@Observable
final class LanguageService {
    private let listSupportedLanguagesUseCase = FoundationModelSupportedLanguagesUseCase()

    private(set) var supportedLanguages: [FoundationModelSupportedLanguage] = []
    private(set) var isLoading = false

    init(autoLoad: Bool = true) {
        if autoLoad {
            Task {
                await loadSupportedLanguages()
            }
        }
    }

    func loadSupportedLanguages() async {
        isLoading = true

        supportedLanguages = listSupportedLanguagesUseCase.execute(locale: .current).languages

        isLoading = false
    }

    func getDisplayName(for language: FoundationModelSupportedLanguage) -> String {
        language.displayName(in: .current)
    }

    func getCurrentUserLanguage() -> String {
        return getCurrentUserLanguageDisplayName()
    }

    func getSupportedLanguageNames() -> [String] {
        // Return display names for all supported languages directly
        return supportedLanguages.map { getDisplayName(for: $0) }.sorted()
    }

    func getCurrentUserLanguageDisplayName() -> String {
        let userLocale = Locale.autoupdatingCurrent
        let languageCode = userLocale.language.languageCode?.identifier ?? "en"
        let regionCode = userLocale.region?.identifier

        for language in supportedLanguages where language.languageCode == languageCode && language.regionCode == regionCode {
            return getDisplayName(for: language)
        }

        for language in supportedLanguages where language.languageCode == languageCode {
            return getDisplayName(for: language)
        }

        if let firstLanguage = supportedLanguages.first {
            return getDisplayName(for: firstLanguage)
        }

        return "English"
    }
}
