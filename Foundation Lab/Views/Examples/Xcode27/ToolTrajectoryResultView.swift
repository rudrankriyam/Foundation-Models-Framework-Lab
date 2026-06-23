//
//  ToolTrajectoryResultView.swift
//  FoundationLab
//

import FoundationLabCore
import SwiftUI

struct ToolTrajectoryResultView: View {
    let evaluation: FoundationLabToolTrajectoryEvaluation
    let observedEvents: [SessionTranscriptSnapshot.ToolEvent]
    let response: String?
    let forbiddenToolNames: Set<String>

    var body: some View {
        VStack(spacing: Spacing.large) {
            Xcode27StatusRow(
                title: String(localized: "Observed comparison"),
                value: verdictTitle,
                systemImage: verdictIcon,
                tint: verdictTint
            )

            Xcode27Section(String(localized: "Observed Transcript Path")) {
                if observedEvents.isEmpty {
                    Text("No tool call or output entries were present in this session transcript.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ToolTrajectoryPathView(observedEvents: observedEvents)
                }
            }

            Xcode27Section(String(localized: "Comparison Evidence")) {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Xcode27KeyValueList(items: [
                        (String(localized: "Observed calls"), evaluation.observed.count.formatted()),
                        (String(localized: "Position mismatches"), evaluation.mismatches.count.formatted()),
                        (String(localized: "Missing calls"), evaluation.missingCalls.count.formatted()),
                        (String(localized: "Extra calls"), evaluation.extraCalls.count.formatted()),
                        (String(localized: "Forbidden calls"), evaluation.forbiddenCalls.count.formatted())
                    ])

                    Text(evidenceSummary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if !evidenceDetails.isEmpty {
                        DisclosureGroup(String(localized: "Inspect Differences")) {
                            Text(evidenceDetails.joined(separator: "\n"))
                                .font(.callout.monospaced())
                                .textSelection(.enabled)
                                .padding(.top, Spacing.small)
                        }
                        .font(.callout)
                    }
                }
            }

            DisclosureGroup(String(localized: "Authored Comparison Contract")) {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text(
                        "This path is declared by the lab; it is not presented as model output. Arguments and order must match."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)

                    ToolTrajectoryPathView(expectedCalls: evaluation.expected)

                    LabeledContent(String(localized: "Forbidden names")) {
                        Text(forbiddenToolNames.sorted().joined(separator: ", "))
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.top, Spacing.small)
            }
            .font(.callout)

            if let response, !response.isEmpty {
                DisclosureGroup(String(localized: "Model Response")) {
                    Text(response)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(.top, Spacing.small)
                }
                .font(.callout)
            }
        }
    }

    private var verdictTitle: String {
        switch evaluation.verdict {
        case .exactMatch:
            String(localized: "Exact match")
        case .differentPath:
            String(localized: "Different path")
        case .forbiddenCall:
            String(localized: "Forbidden call observed")
        }
    }

    private var verdictIcon: String {
        switch evaluation.verdict {
        case .exactMatch:
            "checkmark.circle.fill"
        case .differentPath:
            "exclamationmark.circle.fill"
        case .forbiddenCall:
            "xmark.octagon.fill"
        }
    }

    private var verdictTint: Color {
        switch evaluation.verdict {
        case .exactMatch:
            .green
        case .differentPath:
            .orange
        case .forbiddenCall:
            .red
        }
    }

    private var evidenceSummary: String {
        switch evaluation.verdict {
        case .exactMatch:
            String(localized: "The actual transcript contains the declared tool name, canonical arguments, and order with no extra calls.")
        case .differentPath:
            String(
                localized: """
                The actual transcript differs from the authored contract. Inspect the counts and differences before trusting the path.
                """
            )
        case .forbiddenCall:
            String(localized: "The actual transcript contains a tool name the contract explicitly forbids.")
        }
    }

    private var evidenceDetails: [String] {
        var details = evaluation.mismatches.map { mismatch in
            switch mismatch.kind {
            case .toolName:
                return String(
                    localized: "Position \(mismatch.position + 1): expected \(mismatch.expected.name), observed \(mismatch.observed.name)"
                )
            case .arguments:
                return String(
                    localized: """
                    Position \(mismatch.position + 1): expected \(mismatch.expected.arguments), observed \(mismatch.observed.arguments)
                    """
                )
            }
        }
        details.append(contentsOf: evaluation.missingCalls.map { String(localized: "Missing: \($0.name) \($0.arguments)") })
        details.append(contentsOf: evaluation.extraCalls.map { String(localized: "Extra: \($0.name) \($0.arguments)") })
        details.append(contentsOf: evaluation.forbiddenCalls.map { String(localized: "Forbidden: \($0.name) \($0.arguments)") })
        return details
    }
}
