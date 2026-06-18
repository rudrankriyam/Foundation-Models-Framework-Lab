//
//  EvaluationsLabView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct EvaluationsLabView: View {
    @State private var selectedLayer = EvaluationLayer.dataset

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text(
                    "Evaluations are repeatable tests you run against a dataset. This guide describes the real test workflow; " +
                    "it does not invent scores for a single prompt."
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                Picker("Evaluation layer", selection: $selectedLayer) {
                    ForEach(EvaluationLayer.allCases) { layer in
                        Text(layer.title).tag(layer)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27Section(selectedLayer.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedLayer.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Xcode27KeyValueList(items: selectedLayer.facts)
                    }
                }

                Xcode27Section("What makes a result real") {
                    VStack(alignment: .leading, spacing: 0) {
                        EvaluationEvidenceRow(
                            title: "Known inputs",
                            detail: "Versioned samples cover success, challenge, adversarial, and past-failure cases.",
                            systemImage: "tray.full"
                        )
                        Divider()
                        EvaluationEvidenceRow(
                            title: "Declared criteria",
                            detail: "Each metric has a rule, scale, threshold, or rubric before the suite runs.",
                            systemImage: "checklist"
                        )
                        Divider()
                        EvaluationEvidenceRow(
                            title: "Generated report",
                            detail: "The Evaluations framework records per-sample measurements and aggregate results in the test report.",
                            systemImage: "chart.bar.doc.horizontal"
                        )
                    }
                }

                CodeDisclosure(code: selectedLayer.code)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Evaluations")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Design a test suite before trusting a score")
        #endif
    }
}

private struct EvaluationEvidenceRow: View {
    let title: String
    let detail: String
    let systemImage: String

    var body: some View {
        Xcode27InfoRow(
            title: title,
            detail: detail,
            systemImage: systemImage,
            tint: .blue
        )
        .padding(.vertical, Spacing.small)
    }
}

private enum EvaluationLayer: String, CaseIterable, Identifiable {
    case dataset
    case metric
    case judge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dataset: "Dataset"
        case .metric: "Metrics"
        case .judge: "Model judge"
        }
    }

    var explanation: String {
        switch self {
        case .dataset:
            """
            A representative dataset is the foundation of an evaluation. A synthetic-data pass can expand coverage, but generated \
            samples still need validation before they become test evidence.
            """
        case .metric:
            """
            Use deterministic rules for objective requirements, ground truth when a correct answer exists, and semantic or \
            model-based measurements only when the criterion requires them.
            """
        case .judge:
            """
            A model judge scores qualitative dimensions such as relevance or tone. Calibrate its rubric against human judgment; \
            the judge model and its rubric are part of the test configuration.
            """
        }
    }

    var facts: [(String, String)] {
        switch self {
        case .dataset:
            [
                ("Defines", "Test inputs"),
                ("Include", "Common, edge, adversarial"),
                ("Review", "Synthetic samples"),
                ("Lives in", "Evaluation test target")
            ]
        case .metric:
            [
                ("Rule based", "Objective checks"),
                ("Ground truth", "Known answer"),
                ("Semantic", "Meaning similarity"),
                ("Output", "Per-sample measurement")
            ]
        case .judge:
            [
                ("Use for", "Qualitative criteria"),
                ("Requires", "Explicit scale and rubric"),
                ("Validate with", "Human ratings"),
                ("Model", "Configured by the test")
            ]
        }
    }

    var code: String {
        switch self {
        case .dataset:
            """
            import Evaluations

            // Keep evaluation samples in a test target. Each sample should
            // contain the input plus the reference data your metrics need.
            // Run the complete suite after every prompt or model change.
            """
        case .metric:
            """
            import Evaluations

            // Prefer a deterministic metric when the requirement is exact:
            // forbidden content, required fields, value ranges, or a match
            // against verified ground truth.
            """
        case .judge:
            """
            let evaluator = ModelJudgeEvaluator(
                "TagQuality",
                scale: .numeric([
                    4: "Relevant and helpful",
                    3: "Mostly relevant",
                    2: "Several weak tags",
                    1: "Unhelpful or irrelevant"
                ]),
                judge: PrivateCloudComputeLanguageModel()
            )
            """
        }
    }
}

#Preview {
    NavigationStack {
        EvaluationsLabView()
    }
}
