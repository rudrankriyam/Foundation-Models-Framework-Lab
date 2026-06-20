//
//  RunDetailOverviewSection.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunDetailOverviewSection: View {
    let run: FoundationLabExperimentRun

    var body: some View {
        Section {
            LabeledContent("Status") {
                RunStatusLabel(succeeded: run.succeeded)
            }

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
}
