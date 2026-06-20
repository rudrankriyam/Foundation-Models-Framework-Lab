//
//  HealthMetricRow.swift
//  FoundationLab
//

import SwiftUI

struct HealthMetricRow: View {
    let metricType: MetricType
    let value: Double

    var body: some View {
        LabeledContent {
            Text(metricType.formattedValue(value))
                .foregroundStyle(.secondary)
        } label: {
            Label(metricType.localizedName, systemImage: metricType.icon)
        }
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metricType.localizedName)
        .accessibilityValue(metricType.formattedValue(value))
    }
}

#Preview {
    GroupBox("Health Metrics") {
        VStack(spacing: 0) {
            HealthMetricRow(metricType: .steps, value: 8432)
            Divider()
            HealthMetricRow(metricType: .heartRate, value: 72)
            Divider()
            HealthMetricRow(metricType: .sleep, value: 7.5)
        }
    }
    .padding()
}
