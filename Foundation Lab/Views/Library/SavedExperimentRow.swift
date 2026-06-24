//
//  SavedExperimentRow.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct SavedExperimentRow: View {
    let experiment: FoundationLabExperimentConfiguration

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(experiment.name)
                    .font(.headline)

                Group {
                    if experiment.summary.isEmpty {
                        Text(LocalizedStringKey(experiment.kind.displayName))
                    } else {
                        Text(experiment.summary)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                Label(
                    experiment.modifiedAt.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "clock"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: experiment.kind.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xSmall)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        SavedExperimentRow(
            experiment: FoundationLabExperimentConfiguration(
                name: "Trip Planning Agent",
                summary: "Uses weather and calendar context",
                kind: .toolUse,
                selectedTools: [.weather, .calendar]
            )
        )
    }
}
