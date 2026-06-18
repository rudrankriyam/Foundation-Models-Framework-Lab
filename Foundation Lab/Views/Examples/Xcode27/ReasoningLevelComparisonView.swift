//
//  ReasoningLevelComparisonView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ReasoningLevelComparisonView: View {
    @State private var currentPrompt = "Plan a migration from an Xcode 26 Foundation Models app to Xcode 27."
    @State private var selectedLevel = ReasoningComparisonLevel.moderate

    var body: some View {
        ExampleViewBase(
            title: "Reasoning Levels",
            description: "Compare light, moderate, and deep reasoning contexts",
            defaultPrompt: "Plan a migration from an Xcode 26 Foundation Models app to Xcode 27.",
            currentPrompt: $currentPrompt,
            codeExample: selectedLevel.code,
            onRun: run,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Reasoning level", selection: $selectedLevel) {
                    ForEach(ReasoningComparisonLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(selectedLevel.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedLevel.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        ResultDisplay(
                            result: selectedLevel.expectedShape,
                            isSuccess: true
                        )
                    }
                }

                Xcode27Section("ContextOptions") {
                    Text(
                        """
                        Xcode 27 adds ContextOptions(reasoningLevel:) so examples can make reasoning depth an explicit runtime choice \
                        instead of burying it in prompt wording.
                        """
                    )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func run() {}

    private func reset() {
        currentPrompt = ""
    }
}

private enum ReasoningComparisonLevel: String, CaseIterable, Identifiable {
    case light
    case moderate
    case deep

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }

    var detail: String {
        switch self {
        case .light:
            return "Use light reasoning for fast rewrites, labels, small summaries, and simple classification."
        case .moderate:
            return "Use moderate reasoning for normal app flows where the response needs a little planning."
        case .deep:
            return "Use deep reasoning for migration plans, multi-step tradeoffs, and complex tool orchestration."
        }
    }

    var expectedShape: String {
        switch self {
        case .light:
            return "Expected output: short, direct, low-latency answer with minimal planning."
        case .moderate:
            return "Expected output: structured answer with a few explicit steps and tradeoffs."
        case .deep:
            return "Expected output: fuller plan with assumptions, risks, sequencing, and validation."
        }
    }

    var code: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let context = ContextOptions(
                includeSchemaInPrompt: true,
                reasoningLevel: .\(rawValue)
            )

            let session = LanguageModelSession()
            let response = try await session.respond(
                to: Prompt("Plan the migration."),
                context: context
            )
        }
        """
    }
}

#Preview {
    NavigationStack {
        ReasoningLevelComparisonView()
    }
}
