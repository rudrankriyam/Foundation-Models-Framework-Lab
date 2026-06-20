//
//  DailyProgressView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

struct DailyProgressRow: View {
    let metricType: MetricType
    let currentValue: Double
    let goalValue: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: Double {
        guard goalValue > 0 else { return 0 }
        return min(max(currentValue / goalValue, 0), 1)
    }

    private var progressPercentage: Int {
        Int(progress * 100)
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

            ProgressView(value: progress)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metricType.rawValue)
        .accessibilityValue("\(formattedValue) of \(formattedGoal), \(progressPercentage) percent")
    }

    private var metricLabel: some View {
        Label(metricType.rawValue, systemImage: metricType.icon)
            .foregroundStyle(.primary)
    }

    private var progressLabel: some View {
        Text("\(formattedValue) of \(formattedGoal)")
            .font(.callout)
            .foregroundStyle(.secondary)
    }

    private var formattedValue: String {
        switch metricType {
        case .steps:
            return "\(Int(currentValue)) steps"
        case .activeEnergy:
            return "\(Int(currentValue)) calories"
        case .sleep:
            return String(format: "%.1f hours", currentValue)
        default:
            return "\(Int(currentValue))"
        }
    }

    private var formattedGoal: String {
        switch metricType {
        case .steps:
            return "\(Int(goalValue)) steps"
        case .activeEnergy:
            return "\(Int(goalValue)) calories"
        case .sleep:
            return String(format: "%.0f hours", goalValue)
        default:
            return "\(Int(goalValue))"
        }
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
