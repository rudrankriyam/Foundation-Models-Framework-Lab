//
//  ProductionLanguageExampleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

struct ProductionLanguageExampleView: View {
    @State private var detectedLanguage = ""
    @State private var selectedLanguage = "English (en-US)"
    @State private var foodDescription = "I had 2 scrambled eggs with toast for breakfast"
    @State private var nutritionResult: NutritionAnalysis?
    @State private var isRunning = false
    @State private var errorMessage: String?

    @Environment(LanguageService.self) private var languageService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                languageSelectionSection
                inputSection

                Button("Analyze Nutrition") {
                    Task {
                        await analyzeNutrition()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isRunning || foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal)

                if isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing nutrition...")
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

                if let result = nutritionResult {
                    resultSection(result: result)
                }

                implementationSectionView()
            }
            .padding(.vertical)
        }
        .navigationTitle("Insights Example")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .onAppear {
            detectUserLanguage()
        }
    }

    private var languageSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Language Configuration")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Detected Language: \(detectedLanguage)")
                    .font(.body)
                    .foregroundStyle(.secondary)

                if languageService.isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading supported languages...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Response Language", selection: $selectedLanguage) {
                        // Always include the detected language first
                        if !detectedLanguage.isEmpty {
                            Text(detectedLanguage).tag(detectedLanguage)
                        }

                        // Add English (en-US) if it's not the detected language
                        if detectedLanguage != "English (en-US)" {
                            Text("English (en-US)").tag("English (en-US)")
                        }

                        // Add other supported languages, excluding duplicates
                        ForEach(languageService.getSupportedLanguageNames().filter {
                            $0 != detectedLanguage && $0 != "English (en-US)"
                        }, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }

            }
            .padding(.horizontal)
        }
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Food Description")
                .font(.headline)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: Spacing.small) {
                TextEditor(text: $foodDescription)
                    .font(.body)
                    .padding()
                    .frame(height: 100)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 12))

                Text("Example: \"I had a chicken salad with avocado and olive oil dressing\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }

    private func resultSection(result: NutritionAnalysis) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Nutrition Analysis")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: Spacing.medium) {
                NutritionCard(
                    title: "Parsed Food",
                    value: result.foodName,
                    color: .blue
                )

                HStack(spacing: Spacing.medium) {
                    NutritionCard(
                        title: "Calories",
                        value: "\(result.calories)",
                        color: .orange
                    )

                    NutritionCard(
                        title: "Protein",
                        value: "\(result.proteinGrams)g",
                        color: .green
                    )
                }

                HStack(spacing: Spacing.medium) {
                    NutritionCard(
                        title: "Carbs",
                        value: "\(result.carbsGrams)g",
                        color: .blue
                    )

                    NutritionCard(
                        title: "Fat",
                        value: "\(result.fatGrams)g",
                        color: .red
                    )
                }

                if !result.insights.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("AI Insights")
                            .font(.headline)

                        Text(result.insights)
                            .font(.body)
                            .padding()
                            .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
                            .overlay {
                                RoundedRectangle(cornerRadius: CornerRadius.large)
                                    .stroke(.quaternary, lineWidth: 1)
                            }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func detectUserLanguage() {
        let detected = languageService.getCurrentUserLanguageDisplayName()
        detectedLanguage = detected
        selectedLanguage = detected // Set the detected language as the default selection
    }

    @MainActor
    private func analyzeNutrition() async {
        isRunning = true
        errorMessage = nil
        nutritionResult = nil

        do {
            let response = try await AnalyzeNutritionUseCase().execute(
                AnalyzeNutritionRequest(
                    foodDescription: foodDescription,
                    responseLanguage: selectedLanguage,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            nutritionResult = response.analysis

        } catch {
            errorMessage = "Analysis failed: \(error.localizedDescription)"
        }

        isRunning = false
    }
}

struct NutritionCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.small) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        ProductionLanguageExampleView()
    }
    .environment(LanguageService())
}
