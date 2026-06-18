//
//  EvaluationsLabView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct EvaluationsLabView: View {
    @State private var currentPrompt = "Evaluate whether the assistant produced useful tags and called the right tools."
    @State private var target = EvaluationTarget.judge

    var body: some View {
        ExampleViewBase(
            title: "Evaluations",
            description: "Turn model behavior into measurable checks",
            defaultPrompt: "Evaluate whether the assistant produced useful tags and called the right tools.",
            currentPrompt: $currentPrompt,
            codeExample: target.code,
            onRun: cycleTarget,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Picker("Evaluation", selection: $target) {
                    ForEach(EvaluationTarget.allCases) { target in
                        Text(target.title).tag(target)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(target.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(target.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Xcode27KeyValueList(items: target.metrics)
                    }
                }
            }
        }
    }

    private func cycleTarget() {
        let cases = EvaluationTarget.allCases
        guard let index = cases.firstIndex(of: target) else { return }
        target = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        target = .judge
    }
}

private enum EvaluationTarget: String, CaseIterable, Identifiable {
    case judge
    case synthetic
    case trajectory

    var id: String { rawValue }

    var title: String {
        switch self {
        case .judge: return "Judge"
        case .synthetic: return "Samples"
        case .trajectory: return "Tools"
        }
    }

    var explanation: String {
        switch self {
        case .judge:
            return "Use a model judge when correctness depends on qualitative dimensions such as relevance, helpfulness, or tone."
        case .synthetic:
            return "Generate more samples from a seed dataset, then validate the generated samples before trusting them."
        case .trajectory:
            return "Evaluate not only the final answer but the path: which tools were called, in what order, and with which arguments."
        }
    }

    var metrics: [(String, String)] {
        switch self {
        case .judge:
            return [("Relevance", "4/4"), ("Usefulness", "3/4"), ("Tone", "4/4"), ("Judge", "PCC")]
        case .synthetic:
            return [("Seed", "24"), ("Generated", "100"), ("Valid", "92"), ("Rejected", "8")]
        case .trajectory:
            return [("Expected", "search -> fetch"), ("Actual", "search -> fetch"), ("Tool args", "matched"), ("Result", "pass")]
        }
    }

    var code: String {
        """
        ModelJudgeEvaluator(
            "AnswerQuality",
            judge: PrivateCloudComputeLanguageModel(),
            dimensions: [relevance, usefulness]
        )

        TrajectoryExpectation(ordered: [
            ToolExpectation("search"),
            ToolExpectation("fetchDetails")
        ])
        """
    }
}

#Preview {
    NavigationStack {
        EvaluationsLabView()
    }
}
