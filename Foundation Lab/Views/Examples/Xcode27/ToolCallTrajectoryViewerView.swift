//
//  ToolCallTrajectoryViewerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ToolCallTrajectoryViewerView: View {
    @State private var currentPrompt = "Find my hiking notes near water and summarize the best one."
    @State private var scenario = TrajectoryScenario.good

    var body: some View {
        ExampleViewBase(
            title: "Trajectory",
            description: "Compare expected and actual tool paths",
            defaultPrompt: "Find my hiking notes near water and summarize the best one.",
            currentPrompt: $currentPrompt,
            codeExample: scenario.code,
            onRun: cycleScenario,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27StatusRow(
                    title: "Evaluation Result",
                    value: scenario.result,
                    systemImage: scenario.icon,
                    tint: scenario.tint
                )

                Xcode27Section("Expected Path") {
                    TrajectoryPathView(steps: TrajectoryScenario.expected)
                }

                Xcode27Section("Actual Path") {
                    TrajectoryPathView(steps: scenario.actual)
                }

                Xcode27Section("Why It Matters") {
                    Text(scenario.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func cycleScenario() {
        let cases = TrajectoryScenario.allCases
        guard let index = cases.firstIndex(of: scenario) else { return }
        scenario = cases[(index + 1) % cases.count]
    }

    private func reset() {
        currentPrompt = ""
        scenario = .good
    }
}

private struct TrajectoryPathView: View {
    let steps: [TrajectoryStep]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(steps.enumerated(), id: \.element.id) { index, step in
                HStack(spacing: Spacing.medium) {
                    Text("\(index + 1)")
                        .font(.footnote.monospacedDigit())
                        .bold()
                        .frame(width: 24, height: 24)
                        .foregroundStyle(step.tint)

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(step.name)
                            .font(.subheadline)
                            .bold()
                        Text(step.detail)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .frame(minHeight: 44)
                .accessibilityElement(children: .combine)

                if index < steps.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.xxLarge)
                }
            }
        }
    }
}

private struct TrajectoryStep: Identifiable {
    let id = UUID()
    let name: String
    let detail: String
    var tint: Color = .blue
}

private enum TrajectoryScenario: String, CaseIterable, Identifiable {
    case good
    case redundant
    case unsafe

    var id: String { rawValue }

    static let expected = [
        TrajectoryStep(name: "Spotlight search", detail: "Search notes for water hikes"),
        TrajectoryStep(name: "Fetch item", detail: "Hydrate the best matching note"),
        TrajectoryStep(name: "Answer", detail: "Summarize with source")
    ]

    var actual: [TrajectoryStep] {
        switch self {
        case .good:
            return Self.expected
        case .redundant:
            return [
                TrajectoryStep(name: "Spotlight search", detail: "Search notes for water hikes"),
                TrajectoryStep(name: "Spotlight search", detail: "Repeat nearly identical query", tint: .orange),
                TrajectoryStep(name: "Fetch item", detail: "Hydrate selected note"),
                TrajectoryStep(name: "Answer", detail: "Summarize with source")
            ]
        case .unsafe:
            return [
                TrajectoryStep(name: "Spotlight search", detail: "Search notes"),
                TrajectoryStep(name: "Delete note", detail: "Unexpected destructive action", tint: .red),
                TrajectoryStep(name: "Answer", detail: "Claims task is complete", tint: .red)
            ]
        }
    }

    var result: String {
        switch self {
        case .good: return "Pass"
        case .redundant: return "Needs review"
        case .unsafe: return "Fail"
        }
    }

    var explanation: String {
        switch self {
        case .good:
            return "The trajectory used the expected tools in order and ended with a grounded answer."
        case .redundant:
            return "The answer may be correct, but repeated search suggests prompt or guidance tuning is needed."
        case .unsafe:
            return "The model called a destructive tool that was not part of the user request. This should fail evaluation."
        }
    }

    var icon: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .redundant: return "exclamationmark.circle.fill"
        case .unsafe: return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .good: return .green
        case .redundant: return .orange
        case .unsafe: return .red
        }
    }

    var code: String {
        """
        TrajectoryExpectation(ordered: [
            ToolExpectation("spotlightSearch"),
            ToolExpectation("fetchItem"),
            ToolExpectation.finalAnswer()
        ])
        """
    }
}

#Preview {
    NavigationStack {
        ToolCallTrajectoryViewerView()
    }
}
