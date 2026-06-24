//
//  RunDetailOverviewSection.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunDetailOverviewSection: View {
    let run: FoundationLabExperimentRun

    var body: some View {
        Section("Overview") {
            VStack(alignment: .leading, spacing: Spacing.small) {
                RunStatusLabel(status: run.status)

                Text(promptSummary)
                    .foregroundStyle(run.prompt.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.xSmall)

            LabeledContent("Started") {
                Text(
                    run.startedAt,
                    format: .dateTime.month(.wide).day().year().hour().minute().second()
                )
            }

            LabeledContent("Duration") {
                Text(
                    Measurement(value: run.duration, unit: UnitDuration.seconds),
                    format: .measurement(
                        width: .wide,
                        usage: .asProvided,
                        numberFormatStyle: .number.precision(.fractionLength(2))
                    )
                )
            }

            if let tokenCount = run.tokenCount {
                LabeledContent("Context tokens after run") {
                    Text(tokenCount, format: .number)
                }
            }
        }
    }

    private var promptSummary: String {
        run.prompt.isEmpty ? String(localized: "No prompt was recorded") : run.prompt
    }
}
