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
            Text(formattedValue)
                .foregroundStyle(.secondary)
        } label: {
            Label(metricType.rawValue, systemImage: metricType.icon)
        }
        .padding(.vertical, Spacing.small)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(metricType.rawValue)
        .accessibilityValue(formattedValue)
    }

    private var formattedValue: String {
        switch metricType {
        case .steps:
            return "\(Int(value)) steps"
        case .activeEnergy:
            return "\(Int(value)) calories"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleep:
            return String(format: "%.1f hours", value)
        case .distance:
            return String(format: "%.1f km", value)
        case .weight:
            return String(format: "%.1f kg", value)
        case .bloodPressure:
            return "\(Int(value)) mmHg"
        case .bloodOxygen:
            return "\(Int(value)) percent"
        }
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
