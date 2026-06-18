//
//  FMCLIPythonPlaygroundView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct FMCLIPythonPlaygroundView: View {
    @State private var currentPrompt = "Show how to prototype a Foundation Models workflow outside the app."
    @State private var surface = ScriptingSurface.cli

    var body: some View {
        ExampleViewBase(
            title: "fm Scripts",
            description: "Prototype Foundation Models workflows with CLI and Python",
            defaultPrompt: "Show how to prototype a Foundation Models workflow outside the app.",
            currentPrompt: $currentPrompt,
            codeExample: surface.code,
            onRun: cycleSurface,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
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
                    }
                }
            }
        }
    }

    private func cycleSurface() {
        let cases = ScriptingSurface.allCases
        guard let index = cases.firstIndex(of: surface) else { return }
        surface = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        surface = .cli
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
        case .evaluation: return "Eval"
        }
    }

    var explanation: String {
        switch self {
        case .cli:
            return "Use the fm command to try prompts, PCC, schemas, and image inputs before building app UI."
        case .python:
            return "Use Python when the workflow needs datasets, batch processing, notebooks, or existing evaluation tooling."
        case .evaluation:
            return "Keep the script path close to the app behavior so prompt changes can be tested outside the UI loop."
        }
    }

    var uses: [(String, String)] {
        switch self {
        case .cli:
            return [("Best for", "quick probes"), ("Input", "files/images"), ("Output", "text/schema"), ("Runtime", "system/PCC")]
        case .python:
            return [("Best for", "pipelines"), ("Tools", "classes"), ("Schemas", "decorators"), ("Data", "batch")]
        case .evaluation:
            return [("Best for", "regression"), ("Judge", "PCC"), ("Dataset", "JSONL"), ("Report", "metrics")]
        }
    }

    var code: String {
        switch self {
        case .cli:
            return """
            fm respond "Summarize this file" --model pcc < notes.md
            fm schema object --name FileTriage --string final_files --array
            """
        case .python:
            return """
            import apple_fm_sdk as fm

            session = fm.LanguageModelSession(
                instructions="Classify support messages."
            )
            result = await session.respond(prompt)
            """
        case .evaluation:
            return """
            dataset = load_samples("samples.jsonl")
            report = await evaluate(
                dataset,
                judge=fm.PrivateCloudComputeLanguageModel()
            )
            """
        }
    }
}

#Preview {
    NavigationStack {
        FMCLIPythonPlaygroundView()
    }
}
