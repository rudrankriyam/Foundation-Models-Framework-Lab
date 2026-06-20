//
//  DailyProgressView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct DailyProgressRow: View {
    let metricType: MetricType
    let currentValue: Double?
    let goalValue: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: Double? {
        guard let currentValue, goalValue > 0 else { return nil }
        return min(max(currentValue / goalValue, 0), 1)
    }

    private var progressPercentage: Int? {
        progress.map { Int($0 * 100) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    metricLabel
                    progressLabel
                }
            } else {
                HStack(alignment: .firstTextBaseline) {
                    metricLabel
                    Spacer()
                    progressLabel
                }
            }

            if let progress {
                ProgressView(value: progress)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metricType.localizedName)
        .accessibilityValue(accessibilityValue)
    }

    private var metricLabel: some View {
        Label(metricType.localizedName, systemImage: metricType.icon)
            .foregroundStyle(.primary)
    }

    private var progressLabel: some View {
        Group {
            if currentValue == nil {
                Text("Unavailable")
            } else {
                Text("\(formattedValue) of \(formattedGoal)")
            }
        }
        .font(.callout)
        .foregroundStyle(.secondary)
    }

    private var formattedValue: String {
        currentValue.map(metricType.formattedValue) ?? String(localized: "Unavailable")
    }

    private var formattedGoal: String {
        metricType.formattedValue(goalValue)
    }

    private var accessibilityValue: String {
        guard let progressPercentage else { return String(localized: "Unavailable") }
        return String(
            localized: "\(formattedValue) of \(formattedGoal), \(progressPercentage) percent"
        )
    }
}

#Preview {
    GroupBox("Daily Progress") {
        VStack {
            DailyProgressRow(metricType: .steps, currentValue: 7234, goalValue: 10000)
            Divider()
            DailyProgressRow(metricType: .activeEnergy, currentValue: 342, goalValue: 500)
            Divider()
            DailyProgressRow(metricType: .sleep, currentValue: 6.5, goalValue: 8)
        }
    }
    .padding()
}
