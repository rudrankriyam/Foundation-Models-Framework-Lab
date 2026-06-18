//
//  ReasoningLevelComparisonView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ReasoningLevelComparisonView: View {
    @State private var selectedLevel = ReasoningComparisonLevel.moderate

    var body: some View {
        ReferenceExampleView(
            title: "Reasoning Levels",
            description: "Inspect light, moderate, and deep ContextOptions",
            codeExample: selectedLevel.code,
            referenceNote: """
            Choose a level to inspect its ContextOptions recipe. This page describes the requested reasoning budget; it does not run a \
            comparison.
            """
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

                        LabeledContent("Framework effect") {
                            Text(selectedLevel.frameworkEffect)
                                .multilineTextAlignment(.trailing)
                        }
                        .font(.callout)
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

    var frameworkEffect: String {
        switch self {
        case .light:
            return "Allows less thinking before the response."
        case .moderate:
            return "Allows a moderate amount of thinking before the response."
        case .deep:
            return "Allows more thinking before the response."
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
