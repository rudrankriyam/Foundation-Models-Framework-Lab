//
//  ToolCallTrajectoryViewerView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ToolCallTrajectoryViewerView: View {
    @State private var fixture = TrajectoryFixture.match

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text(
                    "A trajectory is the ordered path a model takes through tools. These are labeled teaching fixtures, not calls " +
                    "captured from this device. In a real app, derive the path from the session transcript and score it in a test."
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                Picker("Teaching fixture", selection: $fixture) {
                    ForEach(TrajectoryFixture.allCases) { fixture in
                        Text(fixture.title).tag(fixture)
                    }
                }
                .pickerStyle(.segmented)

                Xcode27StatusRow(
                    title: "Fixture comparison",
                    value: fixture.result.title,
                    systemImage: fixture.result.icon,
                    tint: fixture.result.tint
                )

                Xcode27Section("Expected tool path") {
                    TrajectoryPathView(steps: TrajectoryFixture.expected)
                }

                Xcode27Section("Authored fixture") {
                    TrajectoryPathView(steps: fixture.steps)
                }

                Xcode27Section("Why the fixture is classified this way") {
                    Text(fixture.explanation)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Xcode27Section("Production workflow") {
                    Xcode27KeyValueList(items: [
                        ("Observe", "session.transcript"),
                        ("Extract", "Tool call names and arguments"),
                        ("Compare", "Declared expectation"),
                        ("Report", "Evaluations test result")
                    ])
                }

                CodeDisclosure(code: codeExample)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Tool Trajectories")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Compare explicit fixtures, not imaginary runs")
        #endif
    }

    private var codeExample: String {
        """
        let toolCallEntries = session.transcript.compactMap { entry in
            if case .toolCalls(let calls) = entry {
                calls
            } else {
                nil
            }
        }

        // Pass the observed calls and your declared expectation to an
        // evaluation in the test target. Keep the full arguments when
        // correctness depends on more than tool names and order.
        """
    }
}

private struct TrajectoryPathView: View {
    let steps: [TrajectoryStep]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(steps.enumerated(), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: Spacing.medium) {
                    Text(index + 1, format: .number)
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

                    Spacer(minLength: Spacing.small)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.vertical, Spacing.small)
                .accessibilityElement(children: .combine)

                if index < steps.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.xxLarge)
                }
            }
        }
    }
}

private struct TrajectoryStep: Identifiable, Equatable {
    let name: String
    let detail: String
    var tint: Color = .blue

    var id: String { "\(name)-\(detail)" }

    static func == (lhs: TrajectoryStep, rhs: TrajectoryStep) -> Bool {
        lhs.name == rhs.name && lhs.detail == rhs.detail
    }
}

private enum TrajectoryResult {
    case match
    case review
    case fail

    var title: String {
        switch self {
        case .match: "Exact match"
        case .review: "Different path"
        case .fail: "Forbidden call"
        }
    }

    var icon: String {
        switch self {
        case .match: "checkmark.circle.fill"
        case .review: "exclamationmark.circle.fill"
        case .fail: "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .match: .green
        case .review: .orange
        case .fail: .red
        }
    }
}

private enum TrajectoryFixture: String, CaseIterable, Identifiable {
    case match
    case repeated
    case forbidden

    var id: String { rawValue }

    var title: String {
        switch self {
        case .match: "Match"
        case .repeated: "Repeated"
        case .forbidden: "Forbidden"
        }
    }

    static let expected = [
        TrajectoryStep(name: "spotlightSearch", detail: "Search notes for hikes near water"),
        TrajectoryStep(name: "fetchItem", detail: "Load the selected note")
    ]

    var steps: [TrajectoryStep] {
        switch self {
        case .match:
            Self.expected
        case .repeated:
            [
                TrajectoryStep(name: "spotlightSearch", detail: "Search notes for hikes near water"),
                TrajectoryStep(name: "spotlightSearch", detail: "Repeat the same search", tint: .orange),
                TrajectoryStep(name: "fetchItem", detail: "Load the selected note")
            ]
        case .forbidden:
            [
                TrajectoryStep(name: "spotlightSearch", detail: "Search notes for hikes near water"),
                TrajectoryStep(name: "deleteItem", detail: "Delete a note the user only asked to read", tint: .red)
            ]
        }
    }

    var result: TrajectoryResult {
        if steps.contains(where: { $0.name == "deleteItem" }) {
            .fail
        } else if steps == Self.expected {
            .match
        } else {
            .review
        }
    }

    var explanation: String {
        switch result {
        case .match: "The authored calls exactly match the declared names, arguments, and order in this fixture."
        case .review:
            "The fixture reaches the same read operation through an extra call. Your evaluation must declare if that fails."
        case .fail:
            "The fixture contains a forbidden tool. A destructive call is a hard failure even if the answer looks useful."
        }
    }
}

#Preview {
    NavigationStack {
        ToolCallTrajectoryViewerView()
    }
}
