//
//  SessionStateLabTurnView.swift
//  FoundationLab
//

import SwiftUI

struct SessionStateLabTurnView: View {
    let turn: SessionStateLabTurn

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text("Turn \(turn.number)")
                    .font(.headline)

                Spacer(minLength: Spacing.small)

                Text(profileName)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }

            Text(turn.prompt)
                .font(.callout)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Text(turn.response)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Xcode27KeyValueList(items: [
                (String(localized: "Remaining at prompt"), valueLabel(turn.remainingBefore)),
                (String(localized: "Remaining after response"), valueLabel(turn.remainingAfter)),
                (String(localized: "Elapsed"), durationLabel)
            ])
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileName: String {
        turn.usedSpentBudgetProfile ? "SessionStateBudgetProfile" : "SessionStateReplyProfile"
    }

    private func valueLabel(_ value: Int?) -> String {
        value?.formatted() ?? String(localized: "Not reported")
    }

    private var durationLabel: String {
        let components = turn.elapsed.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }
}
