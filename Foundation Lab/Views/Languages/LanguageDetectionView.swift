//
//  LanguageDetectionView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 21/10/2025.
//

import SwiftUI
import FoundationLabCore

struct LanguageDetectionView: View {
    @Environment(LanguageService.self) private var languageService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("See which languages and locales the current Foundation Models runtime reports as supported.")
                    .foregroundStyle(.secondary)

                if languageService.isLoading {
                    ProgressView("Checking language support…")
                        .frame(maxWidth: .infinity, minHeight: 160)
                } else if languageService.supportedLanguages.isEmpty {
                    ContentUnavailableView(
                        "No Languages Reported",
                        systemImage: "character.book.closed",
                        description: Text("Refresh to ask the current runtime again.")
                    )
                } else {
                    languageListSection
                }

                CodeDisclosure(code: codeExample)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Language Detection")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh Languages", systemImage: "arrow.clockwise") {
                    Task {
                        await languageService.loadSupportedLanguages()
                    }
                }
                .disabled(languageService.isLoading)
            }
        }
    }

    private var codeExample: String {
        """
import FoundationLabCore

let result = ListSupportedLanguagesUseCase().execute(locale: .current)

for language in result.languages {
    let code = language.languageCode
    let region = language.regionCode ?? ""

    let name = Locale.current.localizedString(forLanguageCode: code) ?? code
    let displayName = region.isEmpty ? name : "\\(name) (\\(code)-\\(region))"

    print(displayName)
}
"""
    }

    private var languageListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text("Supported Languages")
                    .font(.headline)
                Spacer()
                Text(languageService.supportedLanguages.count, format: .number)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .accessibilityLabel("\(languageService.supportedLanguages.count) languages")
            }

            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(languageService.supportedLanguages.indices, id: \.self) { index in
                    let language = languageService.supportedLanguages[index]

                    LanguageRow(language: language, languageService: languageService)

                    if index < languageService.supportedLanguages.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, Spacing.medium)
            .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.medium))
        }
    }
}

private struct LanguageRow: View {
    let language: SupportedLanguageDescriptor
    let languageService: LanguageService

    var body: some View {
        Label {
            Text(displayName)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: "character.book.closed")
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.medium)
    }

    private var displayName: String {
        languageService.getDisplayName(for: language)
    }
}

#Preview {
    NavigationStack {
        LanguageDetectionView()
    }
    .environment(LanguageService())
}
