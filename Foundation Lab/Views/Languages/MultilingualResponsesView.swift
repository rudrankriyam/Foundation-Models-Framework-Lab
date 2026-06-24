//
//  MultilingualResponsesView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

struct MultilingualResponsesView: View {
    @State private var isRunning = false
    @State private var results: [MultilingualResponseEntry] = []
    @State private var errorMessage: String?

    @Environment(LanguageService.self) private var languageService
    private let generateMultilingualResponsesUseCase = GenerateMultilingualResponsesUseCase()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("Run the same task in several supported languages and compare the model’s responses.")
                    .foregroundStyle(.secondary)

                ToolExecuteButton(
                    "Generate Responses",
                    systemImage: "character.bubble",
                    isRunning: isRunning
                ) {
                    Task { await generateMultilingualResponses() }
                }

                if let errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    .accessibilityElement(children: .combine)
                }

                if !results.isEmpty {
                    resultsSection
                }

                CodeDisclosure(code: codeExample)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Multilingual Responses")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var codeExample: String {
        """
import FoundationLabCore

let prompts: [LanguagePrompt] = [
    .init(name: "English", text: "What is the capital of France?"),
    .init(name: "Spanish", text: "¿Cuál es la capital de España?"),
    .init(name: "French", text: "Quelle est la capitale de l'Allemagne?"),
    .init(name: "German", text: "Was ist die Hauptstadt von Italien?")
]

for prompt in prompts {
    let result = try await GenerateTextUseCase().execute(
        TextGenerationRequest(
            prompt: prompt.text,
            context: CapabilityInvocationContext(source: .app)
        )
    )
    print("\\(prompt.name): \\(result.content)")
}
"""
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Responses")
                .font(.headline)

            LazyVStack(spacing: Spacing.medium) {
                ForEach(results) { result in
                    LanguageResponseCard(result: result)
                }
            }
        }
    }

    @MainActor
    private func generateMultilingualResponses() async {
        isRunning = true
        errorMessage = nil
        results = []
        do {
            let result = try await generateMultilingualResponsesUseCase.execute(
                GenerateMultilingualResponsesRequest(
                    supportedLanguages: languageService.supportedLanguages,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            results = result.responses
        } catch {
            errorMessage = error.localizedDescription
        }

        isRunning = false
    }
}

private struct LanguageResponseCard: View {
    let result: MultilingualResponseEntry

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                LabeledContent("Prompt") {
                    Text(result.prompt)
                        .multilineTextAlignment(.trailing)
                }

                Divider()

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Response")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(result.response)
                        .font(.body)
                        .foregroundStyle(result.isError ? Color.red : Color.primary)
                        .textSelection(.enabled)
                }
            }
            .padding(.top, Spacing.small)
        } label: {
            HStack(spacing: Spacing.small) {
                Text(result.flag)
                    .accessibilityHidden(true)

                Text(result.language)
                    .font(.headline)

                if result.isError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .accessibilityLabel("Error")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MultilingualResponsesView()
    }
    .environment(LanguageService())
}
