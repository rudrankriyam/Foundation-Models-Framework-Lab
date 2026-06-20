//
//  ContextBudgetUsageView.swift
//  FoundationLab
//

import SwiftUI

struct ContextBudgetUsageView: View {
    let simulation: ContextBudgetSimulation
    let measurementNote: String

    var body: some View {
        Xcode27Section(String(localized: "Budget result")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Xcode27StatusRow(
                    title: String(localized: "After app policy"),
                    value: simulation.outcomeTitle,
                    systemImage: simulation.outcomeIcon,
                    tint: outcomeColor
                )

                usageRow(
                    title: String(localized: "Before"),
                    usedTokens: simulation.totalBeforePolicy,
                    tint: .secondary
                )

                usageRow(
                    title: String(localized: "After"),
                    usedTokens: simulation.totalAfterPolicy,
                    tint: outcomeColor
                )

                LabeledContent("After-policy math") {
                    Text(simulation.budgetEquation)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(.secondary)
                }
                .font(.footnote.monospacedDigit())

                Text(measurementNote)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var outcomeColor: Color {
        switch simulation.fitsAfterPolicy {
        case true: .green
        case false: .red
        case nil: .secondary
        }
    }

    private func usageRow(title: String, usedTokens: Int?, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            LabeledContent(title) {
                if let usedTokens {
                    Text("\(usedTokens) / \(simulation.contextSize) tokens")
                        .monospacedDigit()
                } else {
                    Text("Not measured")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.footnote)

            if let usedTokens {
                ProgressView(value: min(Double(usedTokens) / Double(simulation.contextSize), 1))
                    .tint(tint)
                    .accessibilityLabel("\(title) context usage")
                    .accessibilityValue("\(usedTokens) of \(simulation.contextSize) tokens")
            }
        }
    }
}
