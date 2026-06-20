//
//  SavedExperimentRow.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct SavedExperimentRow: View {
    let experiment: FoundationLabExperimentConfiguration

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: experiment.kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(experiment.name)
                    .font(.headline)

                Text(experiment.summary.isEmpty ? experiment.kind.displayName : experiment.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        metadata
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        metadata
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var metadata: some View {
        Label(experiment.level.displayName, systemImage: experiment.level.systemImage)
        Label(
            experiment.modifiedAt.formatted(date: .abbreviated, time: .omitted),
            systemImage: "clock"
        )
    }
}

#Preview {
    List {
        SavedExperimentRow(
            experiment: FoundationLabExperimentConfiguration(
                name: "Trip Planning Agent",
                summary: "Uses weather and calendar context",
                level: .advanced,
                kind: .toolUse,
                selectedTools: [.weather, .calendar]
            )
        )
    }
}
