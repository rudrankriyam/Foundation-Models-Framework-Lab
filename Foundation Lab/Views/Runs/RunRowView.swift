//
//  RunRowView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunRowView: View {
    let run: FoundationLabExperimentRun

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
                .lineLimit(2)

            HStack(spacing: Spacing.small) {
                Text(run.startedAt, style: .time)
                Text("•")
                    .accessibilityHidden(true)
                Text(durationText)
                Text("•")
                    .accessibilityHidden(true)
                Text(run.configuration.modelRuntime.shortName)
                    .lineLimit(1)
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
            .lineLimit(1)
    }

    private var statusLabel: some View {
        RunStatusLabel(succeeded: run.succeeded)
            .font(.subheadline)
    }

    private var experimentName: String {
        run.configuration.name.isEmpty ? "Untitled Experiment" : run.configuration.name
    }

    private var promptSummary: String {
        run.prompt.isEmpty ? "No prompt was recorded" : run.prompt
    }

    private var durationText: String {
        let value = run.duration.formatted(.number.precision(.fractionLength(2)))
        return "\(value) seconds"
    }
}
