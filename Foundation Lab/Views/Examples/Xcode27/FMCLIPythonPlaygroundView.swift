//
//  FMCLIPythonPlaygroundView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct FMCLIPythonPlaygroundView: View {
    @State private var surface = ScriptingSurface.cli

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text("Reference playground")
                            .bold()
                        Text(
                            "Nothing runs inside Foundation Lab. Copy a verified example and run it in Terminal "
                                + "or a Python environment on a supported Mac."
                        )
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "terminal")
                        .foregroundStyle(.orange)
                }
                .font(.callout)
                .padding(Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.orange.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))

                Picker("Surface", selection: $surface) {
                    ForEach(ScriptingSurface.allCases) { surface in
                        Text(surface.title).tag(surface)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(surface.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(surface.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Xcode27KeyValueList(items: surface.uses)

                        Button("Inspect Next Surface", systemImage: "arrow.right", action: cycleSurface)
                            .buttonStyle(.glassProminent)
                    }
                }

                CodeDisclosure(code: surface.code, language: surface.language)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("macOS Scripting")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Use Apple's fm CLI and Foundation Models SDK for Python")
        #endif
    }

    private func cycleSurface() {
        let cases = ScriptingSurface.allCases
        guard let index = cases.firstIndex(of: surface) else { return }
        surface = cases[(index + 1) % cases.count]
    }
}

private enum ScriptingSurface: String, CaseIterable, Identifiable {
    case cli
    case python
    case evaluation

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cli: return "CLI"
        case .python: return "Python"
        case .evaluation: return "Evaluation"
        }
    }

    var explanation: String {
        switch self {
        case .cli:
            return "The fm command ships with macOS 27. Use fm chat for interactive exploration "
                + "and fm respond when a script needs a single response."
        case .python:
            return "The Foundation Models SDK for Python exposes the on-device model to Python 3.10+ "
                + "on Apple silicon Macs with Xcode installed."
        case .evaluation:
            return "Use the Python SDK with notebooks and data tools to run representative prompts, "
                + "record outputs, and compare measurable quality criteria."
        }
    }

    var uses: [(String, String)] {
        switch self {
        case .cli:
            return [("Runs in", "Terminal on macOS 27"), ("Interactive", "fm chat"), ("Automation", "fm respond"), ("Help", "fm --help")]
        case .python:
            return [
                ("Package", "apple_fm_sdk"),
                ("Python", "3.10 or later"),
                ("Hardware", "Apple silicon Mac"),
                ("Setup", "Xcode installed")
            ]
        case .evaluation:
            return [
                ("Input", "representative prompts"),
                ("Output", "recorded responses"),
                ("Measure", "feature-specific criteria"),
                ("Compare", "prompt variants")
            ]
        }
    }

    var language: String {
        switch self {
        case .cli: "shell"
        case .python, .evaluation: "python"
        }
    }

    var code: String {
        switch self {
        case .cli:
            return """
            fm --help
            fm chat
            fm respond "Summarize this document." < notes.md
            """
        case .python:
            return """
            import apple_fm_sdk as fm

            model = fm.SystemLanguageModel()
            is_available, reason = model.is_available()

            if is_available:
                session = fm.LanguageModelSession(model=model)
                response = await session.respond(prompt="Hello!")
                print(response)
            """
        case .evaluation:
            return """
            import apple_fm_sdk as fm

            async def collect_results(prompts: list[str]) -> list[dict[str, str]]:
                session = fm.LanguageModelSession(instructions="Summarize clearly.")
                results = []

                for prompt in prompts:
                    response = await session.respond(prompt)
                    results.append({"prompt": prompt, "response": str(response)})

                return results
            """
        }
    }
}

#Preview {
    NavigationStack {
        FMCLIPythonPlaygroundView()
    }
}
