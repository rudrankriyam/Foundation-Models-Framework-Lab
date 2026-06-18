//
//  DynamicProfileBuilderView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct DynamicProfileBuilderView: View {
    @State private var temperature = 0.4
    @State private var maxTokens = 240.0
    @State private var reasoningLevel = ReasoningLevelChoice.moderate
    @State private var toolMode = DynamicToolMode.allowed

    var body: some View {
        ReferenceExampleView(
            title: "Dynamic Profile",
            description: "Compose a LanguageModelSession.Profile recipe",
            codeExample: codeExample,
            referenceNote: "Adjust the controls to generate a profile recipe. This page does not create a session or send a prompt."
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Profile Controls") {
                    VStack(spacing: Spacing.large) {
                        Xcode27ValueSlider(
                            title: "Temperature",
                            valueText: temperature.formatted(.number.precision(.fractionLength(2))),
                            systemImage: "thermometer.medium",
                            value: $temperature,
                            range: 0...1,
                            step: 0.01
                        )
                        Xcode27ValueSlider(
                            title: "Maximum tokens",
                            valueText: Int(maxTokens).formatted(),
                            systemImage: "text.line.last.and.arrowtriangle.forward",
                            value: $maxTokens,
                            range: 64...1_000
                        )

                        Picker("Reasoning", selection: $reasoningLevel) {
                            ForEach(ReasoningLevelChoice.allCases) { level in
                                Text(level.title).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker("Tools", selection: $toolMode) {
                            ForEach(DynamicToolMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                Xcode27Section("Generated Recipe") {
                    Text(recipePreview)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .padding(.vertical, Spacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var recipePreview: String {
        """
        temperature: \(temperature.formatted(.number.precision(.fractionLength(2))))
        maximumResponseTokens: \(Int(maxTokens))
        reasoningLevel: .\(reasoningLevel.rawValue)
        toolCallingMode: .\(toolMode.rawValue)
        """
    }

    private var codeExample: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let profile = LanguageModelSession.Profile {
                DynamicInstructions("Be concise and developer-focused.")
            }
            .temperature(\(temperature.formatted(.number.precision(.fractionLength(2)))))
            .maximumResponseTokens(\(Int(maxTokens)))
            .reasoningLevel(.\(reasoningLevel.rawValue))
            .toolCallingMode(.\(toolMode.rawValue))

            let session = LanguageModelSession(profile: profile)
        }
        """
    }

}

private enum ReasoningLevelChoice: String, CaseIterable, Identifiable {
    case light
    case moderate
    case deep

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

private enum DynamicToolMode: String, CaseIterable, Identifiable {
    case allowed
    case required
    case disallowed

    var id: String { rawValue }

    var title: String {
        rawValue.capitalized
    }
}

#Preview {
    NavigationStack {
        DynamicProfileBuilderView()
    }
}
