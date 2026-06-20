//
//  ToolCallingModeLabView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import FoundationModels
import SwiftUI

struct ToolCallingModeLabView: View {
    @State private var selectedMode = ToolModeExample.allowed

    var body: some View {
        ReferenceExampleView(
            title: String(localized: "Tool Calling Modes"),
            description: String(localized: "Inspect allowed, required, and disallowed tool behavior"),
            codeExample: selectedMode.code,
            referenceNote: String(
                localized: "Choose a mode to inspect the corresponding GenerationOptions recipe. This page does not call a model or tool."
            )
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Tool mode", selection: $selectedMode) {
                    ForEach(ToolModeExample.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(selectedMode.title) {
                    Text(selectedMode.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Xcode27Section(String(localized: "Behavior Matrix")) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(ToolModeExample.allCases) { mode in
                            HStack {
                                Xcode27InfoRow(
                                    title: mode.title,
                                    detail: mode.shortDescription,
                                    systemImage: mode.icon,
                                    tint: mode == selectedMode ? .blue : .secondary
                                )

                                if mode == selectedMode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .accessibilityLabel("Selected")
                                }
                            }
                            .frame(minHeight: 44)
                            .accessibilityElement(children: .combine)

                            if mode != ToolModeExample.allCases.last {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

}

private enum ToolModeExample: String, CaseIterable, Identifiable {
    case allowed
    case required
    case disallowed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .allowed:
            return String(localized: "Allowed")
        case .required:
            return String(localized: "Required")
        case .disallowed:
            return String(localized: "Disallowed")
        }
    }

    var icon: String {
        switch self {
        case .allowed:
            return "checkmark.circle"
        case .required:
            return "exclamationmark.circle"
        case .disallowed:
            return "nosign"
        }
    }

    var shortDescription: String {
        switch self {
        case .allowed:
            return String(localized: "The model may call tools if they help.")
        case .required:
            return String(localized: "The model must call a tool before answering.")
        case .disallowed:
            return String(localized: "The model must answer without tool calls.")
        }
    }

    var explanation: String {
        switch self {
        case .allowed:
            return String(localized: "Use this for normal agentic flows where a tool is available but not always necessary.")
        case .required:
            return String(
                localized: """
                Use this when the response must be grounded in a tool result. Always define an exit condition; this recipe switches to \
                Allowed after the first tool call so the model can answer.
                """
            )
        case .disallowed:
            return String(localized: "Use this for pure language tasks, drafts, or contexts where external actions would be surprising.")
        }
    }

    var code: String {
        if self == .required {
            return Self.requiredModeCode
        }

        return """
        import FoundationModels
        import FoundationModelsTools

        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let options = GenerationOptions(
                samplingMode: nil,
                temperature: 0.2,
                maximumResponseTokens: 200,
                toolCallingMode: .\(rawValue)
            )

            let session = LanguageModelSession(tools: [WeatherTool()])
            let response = try await session.respond(
                to: Prompt("What is the weather in Cupertino?"),
                options: options
            )
        }
        """
    }

    private static let requiredModeCode = """
    import FoundationModels
    import FoundationModelsTools

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    extension SessionPropertyValues {
        @SessionPropertyEntry
        var weatherToolCallCount = 0
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    struct RequiredWeatherProfile: LanguageModelSession.DynamicProfile {
        @SessionProperty(\\.weatherToolCallCount)
        var weatherToolCallCount

        var body: some LanguageModelSession.DynamicProfile {
            LanguageModelSession.Profile {
                WeatherTool()
            }
            .toolCallingMode(weatherToolCallCount == 0 ? .required : .allowed)
            .onToolCall {
                weatherToolCallCount += 1
            }
        }
    }

    if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
        let session = LanguageModelSession(profile: RequiredWeatherProfile())
        let response = try await session.respond(
            to: Prompt("What is the weather in Cupertino?")
        )
    }
    """
}

#Preview {
    NavigationStack {
        ToolCallingModeLabView()
    }
}
