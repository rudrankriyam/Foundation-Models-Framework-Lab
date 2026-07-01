//
//  ProductionLanguageExampleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModelsKit

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
                Text("Adapt a structured model response to the device language while keeping one typed result.")
                    .foregroundStyle(.secondary)

                Label(
                    "Values are estimates from your description. This example does not read Health data or provide medical guidance.",
                    systemImage: "info.circle"
                )
                .font(.callout)
                .foregroundStyle(.secondary)

                languageSelectionSection
                inputSection

                ToolExecuteButton(
                    "Generate Estimate",
                    systemImage: "text.badge.checkmark",
                    isRunning: isRunning
                ) {
                    Task { await analyzeNutrition() }
                }
                .disabled(isRunning || foodDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if let errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if let result = nutritionResult {
                    resultSection(result: result)
                }

                implementationSectionView()
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Localized App Pattern")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .task {
            if languageService.supportedLanguages.isEmpty {
                await languageService.loadSupportedLanguages()
            }
            detectUserLanguage()
        }
    }

    private var languageSelectionSection: some View {
        GroupBox("Language") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                LabeledContent("Device Language", value: detectedLanguage)

                if languageService.isLoading {
                    ProgressView("Loading supported languages…")
                } else {
                    Picker("Response Language", selection: $selectedLanguage) {
                        if !detectedLanguage.isEmpty {
                            Text(detectedLanguage).tag(detectedLanguage)
                        }

                        if detectedLanguage != "English (en-US)" {
                            Text("English (en-US)").tag("English (en-US)")
                        }

                        ForEach(languageService.getSupportedLanguageNames().filter {
                            $0 != detectedLanguage && $0 != "English (en-US)"
                        }, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    private var inputSection: some View {
        GroupBox("Meal Description") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                TextField("Describe a meal", text: $foodDescription, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)

                Text("Try: I had a chicken salad with avocado and olive oil dressing.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.small)
        }
    }

    private func resultSection(result: NutritionAnalysis) -> some View {
        GroupBox("Generated Estimate") {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                LabeledContent("Parsed Meal", value: result.foodName)
                LabeledContent("Estimated Calories") {
                    Text(result.calories, format: .number)
                        .monospacedDigit()
                }
                LabeledContent("Estimated Protein") {
                    Text("\(result.proteinGrams) g")
                        .monospacedDigit()
                }
                LabeledContent("Estimated Carbohydrates") {
                    Text("\(result.carbsGrams) g")
                        .monospacedDigit()
                }
                LabeledContent("Estimated Fat") {
                    Text("\(result.fatGrams) g")
                        .monospacedDigit()
                }

                if !result.insights.isEmpty {
                    Divider()

                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Model Summary")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(result.insights)
                            .font(.body)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding(.top, Spacing.small)
        }
    }

    private func detectUserLanguage() {
        let detected = languageService.getCurrentUserLanguageDisplayName()
        detectedLanguage = detected
        selectedLanguage = detected
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
                    context: FoundationModelInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            nutritionResult = response.analysis

        } catch {
            errorMessage = String(
                localized: "The estimate couldn’t be generated. \(error.localizedDescription)"
            )
        }

        isRunning = false
    }
}

#Preview {
    NavigationStack {
        ProductionLanguageExampleView()
    }
    .environment(LanguageService())
}
