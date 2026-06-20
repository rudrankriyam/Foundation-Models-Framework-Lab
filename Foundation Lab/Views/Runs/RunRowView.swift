//
//  RunRowView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunRowView: View {
    let run: FoundationLabExperimentRun
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    experimentLabel

                    Spacer(minLength: Spacing.medium)

                    statusLabel
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    experimentLabel
                    statusLabel
                }
            }

            Text(promptSummary)
                .font(.body)
                .foregroundStyle(run.prompt.isEmpty ? .secondary : .primary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.small) {
                    metadata
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    metadata
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private var experimentLabel: some View {
        Label(experimentName, systemImage: run.configuration.kind.systemImage)
            .font(.headline)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
    }

    private var statusLabel: some View {
        RunStatusLabel(status: run.status)
            .font(.subheadline)
    }

    private var experimentName: String {
        run.configuration.name.isEmpty ? String(localized: "Untitled Experiment") : run.configuration.name
    }

    private var promptSummary: String {
        run.prompt.isEmpty ? String(localized: "No prompt was recorded") : run.prompt
    }

    private var durationText: String {
        Measurement(value: run.duration, unit: UnitDuration.seconds).formatted(
            .measurement(
                width: .wide,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            )
        )
    }

    @ViewBuilder
    private var metadata: some View {
        Text(run.startedAt, style: .time)
        Text("•")
            .accessibilityHidden(true)
        Text(durationText)
        Text("•")
            .accessibilityHidden(true)
        Text(run.configuration.modelRuntime.shortName)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
    }
}
