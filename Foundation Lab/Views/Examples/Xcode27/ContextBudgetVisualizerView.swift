//
//  ContextBudgetVisualizerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import Foundation
import FoundationModels
import SwiftUI

struct ContextBudgetVisualizerView: View {
    private static let defaultPrompt = "Use the latest research and our earlier decisions to propose the next three implementation steps."

    @State private var currentPrompt = defaultPrompt
    @State private var policy = ContextBudgetPolicy.keepRecent
    @State private var responseReserve = 640.0
    @State private var measuredPromptTokens: Int?
    @State private var measurementNote = "Run to measure this prompt with the model tokenizer."
    @State private var isRunning = false
    @State private var activeMeasurementID: UUID?

    private var simulation: ContextBudgetSimulation {
        ContextBudgetSimulation(
            contextSize: SystemLanguageModel.default.contextSize,
            promptTokens: measuredPromptTokens ?? estimatedPromptTokens(for: currentPrompt),
            responseReserve: Int(responseReserve),
            policy: policy
        )
    }

    var body: some View {
        ExampleViewBase(
            title: "Transcript Budget Lab",
            description: "Decide what your app keeps before a session runs out of context",
            defaultPrompt: Self.defaultPrompt,
            currentPrompt: $currentPrompt,
            isRunning: isRunning,
            codeExample: codeExample,
            runLabel: "Measure Prompt",
            onRun: runSimulation,
            onReset: reset
        ) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                frameworkBoundary
                policyControls
                ContextBudgetUsageView(simulation: simulation, measurementNote: measurementNote)

                Xcode27Section("Sample transcript after policy") {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text(
                            "These entries and their history counts are a fixed teaching sample. "
                            + "Measure Prompt tokenizes only the prompt above."
                        )
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            ForEach(simulation.processedEntries) { entry in
                                ContextBudgetEntryRow(entry: entry)

                                if entry.id != simulation.processedEntries.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                Xcode27Section("What happens next") {
                    Label(simulation.recommendation, systemImage: simulation.outcomeIcon)
                        .font(.callout)
                        .foregroundStyle(simulation.fitsAfterPolicy ? Color.primary : Color.red)
                }
            }
        }
        .onChange(of: currentPrompt) {
            invalidatePromptMeasurement()
        }
    }

    private var frameworkBoundary: some View {
        Xcode27Section("Framework boundary") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text(
                    "Foundation Models can report the context limit and count tokens. "
                    + "It does not choose a ‘balanced’ or ‘aggressive’ compaction strategy for your app."
                )
                    .font(.callout)

                Label("Framework: context size, token counts, transcript, and overflow error", systemImage: "apple.intelligence")
                Label("Your app: response reserve and which history to keep, summarize, or drop", systemImage: "slider.horizontal.3")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var policyControls: some View {
        Xcode27Section("App-owned policy") {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                LabeledContent("Transcript policy") {
                    Picker("Transcript policy", selection: $policy) {
                        ForEach(ContextBudgetPolicy.allCases) { policy in
                            Label(policy.title, systemImage: policy.systemImage)
                                .tag(policy)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                }

                Text(policy.explanation)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Xcode27ValueSlider(
                    title: "Response reserve",
                    valueText: "\(Int(responseReserve)) tokens",
                    systemImage: "arrow.down.doc",
                    value: $responseReserve,
                    range: 256...1_024,
                    step: 64
                )

                Text("The reserve mirrors GenerationOptions.maximumResponseTokens: space held back for the model’s answer.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func runSimulation() {
        let prompt = currentPrompt
        let measurementID = UUID()
        let fallback = estimatedPromptTokens(for: prompt)

        activeMeasurementID = measurementID
        isRunning = true
        measuredPromptTokens = nil
        measurementNote = "Measuring prompt tokens…"

        Task { @MainActor in
            let tokens: Int
            let note: String

            do {
                if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
                    tokens = try await SystemLanguageModel.default.tokenCount(for: Prompt(prompt))
                    note = "Prompt measured with SystemLanguageModel.tokenCount(for:)."
                } else {
                    tokens = fallback
                    note = "Prompt estimated because model token counting requires version 26.4 or later."
                }
            } catch {
                tokens = fallback
                note = "Prompt estimated because the model tokenizer was unavailable."
            }

            guard activeMeasurementID == measurementID, currentPrompt == prompt else { return }

            measuredPromptTokens = tokens
            measurementNote = note
            isRunning = false
            activeMeasurementID = nil
        }
    }

    private func reset() {
        activeMeasurementID = nil
        isRunning = false
        currentPrompt = ""
        policy = .keepRecent
        responseReserve = 640
        measuredPromptTokens = nil
        measurementNote = "Enter a prompt, then run to measure it with the model tokenizer."
    }

    private func invalidatePromptMeasurement() {
        activeMeasurementID = nil
        isRunning = false
        measuredPromptTokens = nil
        measurementNote = currentPrompt.isEmpty
            ? "Enter a prompt, then run to measure it with the model tokenizer."
            : "Prompt changed. Run to measure it with the model tokenizer."
    }

    private func estimatedPromptTokens(for prompt: String) -> Int {
        max(1, Int(ceil(Double(prompt.count) / 4.5)))
    }

    private var codeExample: String {
        """
        let model = SystemLanguageModel.default
        let contextSize = model.contextSize
        let historyTokens = try await model.tokenCount(for: session.transcript)
        let promptTokens = try await model.tokenCount(for: Prompt(prompt))

        let options = GenerationOptions(maximumResponseTokens: \(Int(responseReserve)))
        let requiredTokens = historyTokens + promptTokens + \(Int(responseReserve))

        if requiredTokens > contextSize {
            // App policy: rebuild a smaller Transcript before creating the next session.
            let compactedEntries = preparedEntries(from: session.transcript)
            session = LanguageModelSession(transcript: Transcript(entries: compactedEntries))
        }

        do {
            try await session.respond(to: prompt, options: options)
        } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
            // Reduce history or start a fresh session, then retry intentionally.
        }
        """
    }
}

#Preview {
    NavigationStack {
        ContextBudgetVisualizerView()
    }
}
