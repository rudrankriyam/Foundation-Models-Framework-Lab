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
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                descriptionSection

                Button("Refresh Supported Languages") {
                    Task {
                        await languageService.loadSupportedLanguages()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(languageService.isLoading)
                .padding(.horizontal)

                if languageService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading languages...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if !languageService.supportedLanguages.isEmpty {
                    languageListSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Language Detection")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            CodeViewer(
                code: """
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
            )
        }
        .padding(.horizontal)
    }

    private var languageListSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Supported Languages (\(languageService.supportedLanguages.count))")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Spacing.small) {
                ForEach(languageService.supportedLanguages.indices, id: \.self) { index in
                    let language = languageService.supportedLanguages[index]
                    LanguageCard(language: language, languageService: languageService)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LanguageCard: View {
    let language: SupportedLanguageDescriptor
    let languageService: LanguageService

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(displayName)
                .font(.body)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var displayName: String {
        return languageService.getDisplayName(for: language)
    }
}

#Preview {
    NavigationStack {
        LanguageDetectionView()
    }
    .environment(LanguageService())
}
