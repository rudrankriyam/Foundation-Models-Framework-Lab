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
    @State private var measuredHistoryTokens: [String: Int]?
    @State private var measurementNote = "Measure the prompt and sample transcript with the model tokenizer."
    @State private var isRunning = false
    @State private var activeMeasurementID: UUID?

    private var simulation: ContextBudgetSimulation {
        ContextBudgetSimulation(
            contextSize: SystemLanguageModel.default.contextSize,
            promptTokens: measuredPromptTokens,
            historyTokenCounts: measuredHistoryTokens,
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
            runLabel: "Measure Budget",
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
                            "This is a synthetic long conversation for comparing app-owned policies. "
                            + "Its displayed counts come from the same model tokenizer as your prompt."
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
                        .foregroundStyle(simulation.fitsAfterPolicy == false ? Color.red : Color.primary)
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
        activeMeasurementID = measurementID
        isRunning = true
        measuredPromptTokens = nil
        measuredHistoryTokens = nil
        measurementNote = "Measuring prompt and sample transcript…"

        Task { @MainActor in
            do {
                if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
                    let model = SystemLanguageModel.default
                    let promptTokens = try await model.tokenCount(for: Prompt(prompt))
                    var historyTokens: [String: Int] = [:]

                    for sample in ContextBudgetSimulation.entriesToMeasure {
                        historyTokens[sample.id] = try await model.tokenCount(for: [sample.transcriptEntry])
                    }

                    guard activeMeasurementID == measurementID, currentPrompt == prompt else { return }

                    measuredPromptTokens = promptTokens
                    measuredHistoryTokens = historyTokens
                    measurementNote = "Measured with SystemLanguageModel.tokenCount(for:)."
                } else {
                    measurementNote = "Model token counting requires version 26.4 or later; no estimates are shown."
                }
            } catch {
                measurementNote = "The model tokenizer is unavailable; no estimates are shown."
            }

            guard activeMeasurementID == measurementID, currentPrompt == prompt else { return }

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
        measuredHistoryTokens = nil
        measurementNote = "Enter a prompt, then measure it with the sample transcript."
    }

    private func invalidatePromptMeasurement() {
        activeMeasurementID = nil
        isRunning = false
        measuredPromptTokens = nil
        measuredHistoryTokens = nil
        measurementNote = currentPrompt.isEmpty
            ? "Enter a prompt, then measure it with the sample transcript."
            : "Prompt changed. Measure again to update the budget."
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
