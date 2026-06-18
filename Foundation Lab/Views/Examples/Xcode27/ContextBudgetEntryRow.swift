//
//  ContextBudgetEntryRow.swift
//  FoundationLab
//

import SwiftUI

struct ContextBudgetEntryRow: View {
    let entry: ContextBudgetSimulation.Entry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
            Image(systemName: entry.disposition.systemImage)
                .foregroundStyle(dispositionColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(entry.title)
                    .font(.subheadline)
                    .bold()

                Text("\(entry.kind) · \(entry.disposition.title)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.small)

            VStack(alignment: .trailing, spacing: Spacing.xSmall) {
                if let resultingTokens = entry.resultingTokens {
                    Text("\(resultingTokens) tokens")
                        .font(.footnote.monospacedDigit())
                } else {
                    Text("Not measured")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let originalTokens = entry.originalTokens,
                   let resultingTokens = entry.resultingTokens,
                   originalTokens != resultingTokens {
                    Text("was \(originalTokens)")
                        .font(.footnote.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }

    private var dispositionColor: Color {
        switch entry.disposition {
        case .kept: .green
        case .summarized: .orange
        case .dropped: .secondary
        }
    }
}
