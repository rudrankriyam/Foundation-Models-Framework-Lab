//
//  ContextWindowInspectorView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import FoundationModels
import SwiftUI

struct ContextWindowInspectorView: View {
    @State private var currentPrompt = """
    You are a helpful assistant. Explain Foundation Models, then call tools if needed.
    """
    @State private var instructionsTokens = 180.0
    @State private var promptTokens = 120.0
    @State private var schemaTokens = 520.0
    @State private var toolTokens = 740.0
    @State private var historyTokens = 1_240.0
    @State private var responseReserveTokens = 600.0

    private var maxContextSize: Int {
        SystemLanguageModel.default.contextSize
    }

    private var totalTokens: Int {
        Int(instructionsTokens + promptTokens + schemaTokens + toolTokens + historyTokens + responseReserveTokens)
    }

    private var usageFraction: Double {
        min(Double(totalTokens) / Double(maxContextSize), 1)
    }

    var body: some View {
        ExampleViewBase(
            title: "Context Window",
            description: "Inspect the pieces that consume a session budget",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: rebalance,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27StatusRow(
                    title: "Current Budget",
                    value: "\(totalTokens) / \(maxContextSize) tokens",
                    systemImage: "chart.bar.xaxis",
                    tint: usageFraction > 0.9 ? .red : usageFraction > 0.75 ? .orange : .green
                )

                TokenUsageBar(
                    currentTokenCount: totalTokens,
                    maxContextSize: maxContextSize,
                    tokenUsageFraction: usageFraction
                )

                Xcode27Section("Token Sources") {
                    VStack(spacing: Spacing.large) {
                        Xcode27ValueSlider(
                            title: "Instructions",
                            valueText: "\(Int(instructionsTokens)) tokens",
                            systemImage: "text.quote",
                            value: $instructionsTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: "Prompt",
                            valueText: "\(Int(promptTokens)) tokens",
                            systemImage: "text.cursor",
                            value: $promptTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: "Schemas",
                            valueText: "\(Int(schemaTokens)) tokens",
                            systemImage: "curlybraces",
                            value: $schemaTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: "Tools",
                            valueText: "\(Int(toolTokens)) tokens",
                            systemImage: "hammer",
                            value: $toolTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: "History",
                            valueText: "\(Int(historyTokens)) tokens",
                            systemImage: "clock.arrow.circlepath",
                            value: $historyTokens,
                            range: 0...2_000,
                            step: 20
                        )
                        Xcode27ValueSlider(
                            title: "Response reserve",
                            valueText: "\(Int(responseReserveTokens)) tokens",
                            systemImage: "arrow.down.doc",
                            value: $responseReserveTokens,
                            range: 0...2_000,
                            step: 20
                        )
                    }
                }

                Xcode27Section("Compaction Trigger") {
                    Text(compactionAdvice)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var compactionAdvice: String {
        switch usageFraction {
        case ..<0.65:
            return "The session has plenty of room. Keep the transcript intact."
        case ..<0.85:
            return "The session is getting warm. Consider summarizing older turns before adding large schemas or tool output."
        default:
            return "The session is close to the context limit. Compact history or start a fresh session before asking for a long response."
        }
    }

    private func rebalance() {
        let promptEstimate = max(40, currentPrompt.split(separator: " ").count * 2)
        promptTokens = Double(promptEstimate)
    }

    private func reset() {
        currentPrompt = ""
        instructionsTokens = 180
        promptTokens = 120
        schemaTokens = 520
        toolTokens = 740
        historyTokens = 1_240
        responseReserveTokens = 600
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
