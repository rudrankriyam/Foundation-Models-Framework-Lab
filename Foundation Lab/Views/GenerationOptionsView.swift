//
//  GenerationOptionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/20/25.
//

import SwiftUI
import FoundationLabCore

struct GenerationOptionsView: View {
    @State private var temperature: Double = 0.7
    @State private var topK: Int = 50
    @State private var topP: Double = 0.9
    @State private var maximumResponseTokens: Int = 500
    @State private var useSampling: Bool = true
    @State private var samplingMode: SamplingType = .nucleus

    @State private var prompt: String = "Write a creative story about a magical forest"
    @State private var response: String = ""
    @State private var isGenerating: Bool = false
    @State private var showError: String?
    @State private var lastTokenCount: Int?
    @State private var contextSize: Int = AppConfiguration.TokenManagement.defaultMaxTokens

    private let generateTextUseCase = GenerateTextUseCase()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                headerView
                promptSection
                optionsSection
                generateSection
                responseSection
            }
            .padding()
        }
        .navigationTitle("Generation Options")
        .task {
            contextSize = await AppConfiguration.TokenManagement.contextSize()
        }
    }
}

// MARK: - View Components

private extension GenerationOptionsView {
    private var headerView: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text("Experiment with Generation Parameters")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Adjust these parameters to see how they affect the model's creativity and output quality.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Prompt")
                .font(.headline)

            TextField("Enter your prompt...", text: $prompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            Text("Generation Parameters")
                .font(.headline)

            VStack(spacing: Spacing.large) {
                // Temperature
                temperatureSliderView(binding: $temperature)

                // Sampling Section
                samplingSection

                // Max Response Tokens
                maxTokensSliderView(binding: $maximumResponseTokens)
            }
        }
        .padding()
    }

    private var samplingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Sampling Strategy")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(alignment: .leading, spacing: Spacing.small) {
                Toggle("Use Custom Sampling", isOn: $useSampling)
                    .font(.caption)

                if useSampling {
                    Picker("Sampling Mode", selection: $samplingMode) {
                        ForEach(SamplingType.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(samplingMode.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if samplingMode == .topK {
                        HStack {
                            Text("Top-K Value")
                                .font(.caption)
                            Spacer()
                            Text("\(topK)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: Binding(
                            get: { Double(topK) },
                            set: { topK = Int($0) }
                        ), in: 1...100, step: 1)
                    } else if samplingMode == .nucleus {
                        HStack {
                            Text("Probability Threshold")
                                .font(.caption)
                            Spacer()
                            Text(String(format: "%.2f", topP))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Slider(value: $topP, in: 0.1...1.0, step: 0.05)
                    }
                }
            }
        }
        .padding()
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var generateSection: some View {
        Button(action: generateResponse) {
            HStack {
                if isGenerating {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "sparkles")
                }
                Text(isGenerating ? "Generating..." : "Generate Response")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .buttonStyle(.glass)
        .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGenerating)
    }

    @ViewBuilder
    private var responseSection: some View {
        if !response.isEmpty || showError != nil {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                HStack {
                    Text("Generated Response")
                        .font(.headline)
                    Spacer()
                    Button("Clear") {
                        response = ""
                        showError = nil
                    }
                    .buttonStyle(.glassProminent)
                    .font(.caption)
                }

                if let error = showError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(CornerRadius.small)
                } else if !response.isEmpty {
                    ScrollView {
                        Text(response)
                            .font(.body)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 300)

                    if let lastTokenCount {
                        HStack {
                            Label("\(lastTokenCount) / \(contextSize) tokens used", systemImage: "number.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func generateResponse() {
        Task {
            await performGeneration()
        }
    }

    @MainActor
    private func performGeneration() async {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isGenerating = true
        showError = nil
        response = ""
        lastTokenCount = nil

        do {
            let config = GenerationConfig(
                useSampling: useSampling,
                samplingMode: samplingMode,
                topK: topK,
                topP: topP,
                temperature: temperature,
                maximumResponseTokens: maximumResponseTokens
            )
            let options = createGenerationOptions(from: config)

            let generatedResponse = try await generateTextUseCase.execute(
                TextGenerationRequest(
                    prompt: prompt,
                    generationOptions: options,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )

            response = generatedResponse.content
            lastTokenCount = generatedResponse.metadata.tokenCount
        } catch {
            showError = error.localizedDescription
        }

        isGenerating = false
    }
}

#Preview {
    GenerationOptionsView()
}
