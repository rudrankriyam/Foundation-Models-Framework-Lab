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
                descriptionSection

                Button("Generate Multilingual Responses") {
                    Task {
                        await generateMultilingualResponses()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRunning)
                .padding(.horizontal)

                if isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating responses...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                if !results.isEmpty {
                    resultsSection
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Multilingual Play")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {

            CodeViewer(
                code: """
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
            )
        }
        .padding(.horizontal)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Generated Responses")
                .font(.headline)
                .padding(.horizontal)

            LazyVStack(spacing: Spacing.medium) {
                ForEach(results) { result in
                    LanguageResponseCard(result: result)
                }
            }
            .padding(.horizontal)
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

struct LanguageResponseCard: View {
    let result: MultilingualResponseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack {
                Text(result.flag)
                    .font(.title2)

                Text(result.language)
                    .font(.headline)
                    .fontWeight(.medium)

                Spacer()

                if result.isError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("PROMPT")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(result.prompt)
                    .font(.body)
                    .padding(.bottom, Spacing.small)

                Text("RESPONSE")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(result.response)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(result.isError ? .red : .primary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        MultilingualResponsesView()
    }
    .environment(LanguageService())
}
