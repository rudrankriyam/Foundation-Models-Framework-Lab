//
//  ContextWindowInspectorView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import FoundationModels
import SwiftUI

struct ContextWindowInspectorView: View {
    private static let defaultPrompt = """
    You are a helpful assistant. Explain Foundation Models, then call tools if needed.
    """

    @State private var currentPrompt = defaultPrompt
    @State private var instructionsTokens = 180.0
    @State private var promptTokens = 0.0
    @State private var schemaTokens = 520.0
    @State private var toolTokens = 740.0
    @State private var historyTokens = 1_240.0
    @State private var responseReserveTokens = 600.0
    @State private var measuredPromptTokens: Double?
    @State private var isMeasuring = false
    @State private var errorMessage: String?
    @State private var measurementID = UUID()

    private var maxContextSize: Int { SystemLanguageModel.default.contextSize }

    private var totalTokens: Int {
        Int(instructionsTokens + promptTokens + schemaTokens + toolTokens + historyTokens + responseReserveTokens)
    }

    private var usageFraction: Double { min(Double(totalTokens) / Double(maxContextSize), 1) }

    var body: some View {
        ExampleViewBase(
            title: String(localized: "Context Window"),
            description: String(localized: "Inspect the pieces that consume a session budget"),
            currentPrompt: $currentPrompt,
            isRunning: isMeasuring,
            errorMessage: errorMessage,
            codeExample: codeExample,
            runLabel: String(localized: "Measure"),
            onRun: measurePrompt,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27StatusRow(
                    title: String(localized: "Current Budget"),
                    value: String(localized: "\(totalTokens) / \(maxContextSize) tokens"),
                    systemImage: "chart.bar.xaxis",
                    tint: usageFraction > 0.9 ? .red : usageFraction > 0.75 ? .orange : .green
                )

                TokenUsageBar(
                    currentTokenCount: totalTokens,
                    maxContextSize: maxContextSize,
                    tokenUsageFraction: usageFraction
                )

                Xcode27StatusRow(
                    title: String(localized: "Prompt"),
                    value: promptTokenSource,
                    systemImage: measuredPromptTokens == promptTokens ? "checkmark.seal" : "slider.horizontal.3",
                    tint: measuredPromptTokens == promptTokens ? .green : .blue
                )

                Xcode27Section(String(localized: "Token Sources")) {
                    VStack(spacing: Spacing.large) {
                        Xcode27ValueSlider(
                            title: String(localized: "Instructions"),
                            valueText: String(localized: "\(Int(instructionsTokens)) tokens"),
                            systemImage: "text.quote",
                            value: $instructionsTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: String(localized: "Prompt"),
                            valueText: promptTokens == 0
                                ? String(localized: "Not measured")
                                : String(localized: "\(Int(promptTokens)) tokens"),
                            systemImage: "text.cursor",
                            value: $promptTokens,
                            range: 0...max(2_000, promptTokens),
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: String(localized: "Schemas"),
                            valueText: String(localized: "\(Int(schemaTokens)) tokens"),
                            systemImage: "curlybraces",
                            value: $schemaTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: String(localized: "Tools"),
                            valueText: String(localized: "\(Int(toolTokens)) tokens"),
                            systemImage: "hammer",
                            value: $toolTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: String(localized: "History"),
                            valueText: String(localized: "\(Int(historyTokens)) tokens"),
                            systemImage: "clock.arrow.circlepath",
                            value: $historyTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: String(localized: "Response reserve"),
                            valueText: String(localized: "\(Int(responseReserveTokens)) tokens"),
                            systemImage: "arrow.down.doc",
                            value: $responseReserveTokens,
                            range: 0...2_000,
                            step: 20
                        )
                    }
                }

                Xcode27Section(String(localized: "Compaction Trigger")) {
                    Text(compactionAdvice)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Xcode27Section(String(localized: "Scope")) {
                    Text(
                        String(
                            localized: """
                            Context size comes from the system model. Measure uses the model tokenizer; the other sliders are local \
                            planning estimates that you can adjust to explore a session budget.
                            """
                        )
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .onChange(of: currentPrompt) {
            measuredPromptTokens = nil
            promptTokens = 0
        }
    }
}

private extension ContextWindowInspectorView {
    var compactionAdvice: String {
        switch usageFraction {
        case ..<0.65:
            return String(localized: "The session has plenty of room. Keep the transcript intact.")
        case ..<0.85:
            return String(
                localized: """
                The session is getting warm. Consider summarizing older turns before adding large schemas or tool output.
                """
            )
        default:
            return String(
                localized: """
                The session is close to the context limit. Compact history or start a fresh session before asking for a long response.
                """
            )
        }
    }

    private var promptTokenSource: String {
        measuredPromptTokens == promptTokens
            ? String(localized: "Measured with SystemLanguageModel.tokenCount(for:).")
            : String(localized: "Not measured")
    }

    private func measurePrompt() async {
        let id = UUID()
        let prompt = currentPrompt
        measurementID = id
        isMeasuring = true
        errorMessage = nil

        defer {
            if measurementID == id {
                isMeasuring = false
            }
        }

        guard #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) else {
            guard measurementID == id else { return }
            errorMessage = String(localized: "Model token counting requires version 26.4 or later; no estimates are shown.")
            return
        }

        do {
            let count = try await SystemLanguageModel.default.tokenCount(for: prompt)
            try Task.checkCancellation()
            guard measurementID == id, currentPrompt == prompt else { return }
            promptTokens = Double(count)
            measuredPromptTokens = Double(count)
        } catch is CancellationError {
            return
        } catch {
            guard measurementID == id, currentPrompt == prompt else { return }
            errorMessage = error.localizedDescription
        }
    }

    private func reset() {
        measurementID = UUID()
        isMeasuring = false
        currentPrompt = Self.defaultPrompt
        instructionsTokens = 180
        promptTokens = 0
        schemaTokens = 520
        toolTokens = 740
        historyTokens = 1_240
        responseReserveTokens = 600
        measuredPromptTokens = nil
        errorMessage = nil
    }

    private var codeExample: String {
        """
        let model = SystemLanguageModel.default
        let maxContextSize = model.contextSize
        let tokenCount = try await model.tokenCount(for: transcriptEntries)

        if Double(tokenCount) / Double(maxContextSize) > 0.85 {
            // Summarize older entries or start a fresh session.
        }
        """
    }
}

#Preview {
    NavigationStack {
        ContextWindowInspectorView()
    }
}
