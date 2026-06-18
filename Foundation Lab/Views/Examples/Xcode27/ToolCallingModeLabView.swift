//
//  ToolCallingModeLabView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import FoundationModels
import SwiftUI

struct ToolCallingModeLabView: View {
    @State private var currentPrompt = "What is the weather in Cupertino?"
    @State private var selectedMode = ToolModeExample.allowed

    var body: some View {
        ExampleViewBase(
            title: "Tool Modes",
            description: "Compare allowed, required, and disallowed tool calling",
            defaultPrompt: "What is the weather in Cupertino?",
            currentPrompt: $currentPrompt,
            codeExample: selectedMode.code,
            onRun: run,
            onReset: reset
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

                Xcode27Section("Behavior Matrix") {
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

    private func run() {}

    private func reset() {
        currentPrompt = ""
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
            return "Allowed"
        case .required:
            return "Required"
        case .disallowed:
            return "Disallowed"
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
            return "The model may call tools if they help."
        case .required:
            return "The model must call a tool before answering."
        case .disallowed:
            return "The model must answer without tool calls."
        }
    }

    var explanation: String {
        switch self {
        case .allowed:
            return "Use this for normal agentic flows where a tool is available but not always necessary."
        case .required:
            return "Use this when the response must be grounded in a tool result, such as weather, calendar, or search."
        case .disallowed:
            return "Use this for pure language tasks, drafts, or contexts where external actions would be surprising."
        }
    }

    var code: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let options = GenerationOptions(
                samplingMode: nil,
                temperature: 0.2,
                maximumResponseTokens: 200,
                toolCallingMode: .\(rawValue)
            )

            let session = LanguageModelSession(tools: [weatherTool])
            let response = try await session.respond(
                to: Prompt("What is the weather in Cupertino?"),
                options: options
            )
        }
        """
    }
}

#Preview {
    NavigationStack {
        ToolCallingModeLabView()
    }
}
