//
//  HealthMetric.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData

@Model
final class HealthMetric {
    var id: UUID
    var type: MetricType
    var value: Double
    var unit: String
    var timestamp: Date
    var notes: String?

    init(type: MetricType, value: Double, unit: String, timestamp: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.type = type
        self.value = value
        self.unit = unit
        self.timestamp = timestamp
        self.notes = notes
    }
}

enum MetricType: String, Codable, CaseIterable, Sendable {
    case steps = "Steps"
    case heartRate = "Heart Rate"
    case sleep = "Sleep"
    case activeEnergy = "Active Energy"
    case distance = "Distance"
    case weight = "Weight"
    case bloodPressure = "Blood Pressure"
    case bloodOxygen = "Blood Oxygen"

    var localizedName: String {
        switch self {
        case .steps: String(localized: "Steps")
        case .heartRate: String(localized: "Heart Rate")
        case .sleep: String(localized: "Sleep")
        case .activeEnergy: String(localized: "Active Energy")
        case .distance: String(localized: "Distance")
        case .weight: String(localized: "Weight")
        case .bloodPressure: String(localized: "Blood Pressure")
        case .bloodOxygen: String(localized: "Blood Oxygen")
        }
    }

    func formattedValue(_ value: Double) -> String {
        switch self {
        case .steps:
            String(localized: "\(Int(value)) steps")
        case .activeEnergy:
            Measurement(value: value, unit: UnitEnergy.kilocalories).formatted(
                .measurement(width: .abbreviated, usage: .asProvided)
            )
        case .heartRate:
            String(localized: "\(Int(value)) bpm")
        case .sleep:
            Measurement(value: value, unit: UnitDuration.hours).formatted(
                .measurement(width: .abbreviated, usage: .asProvided)
            )
        case .distance:
            Measurement(value: value, unit: UnitLength.kilometers).formatted(
                .measurement(width: .abbreviated, usage: .asProvided)
            )
        case .weight:
            Measurement(value: value, unit: UnitMass.kilograms).formatted(
                .measurement(width: .abbreviated, usage: .asProvided)
            )
        case .bloodPressure:
            String(localized: "\(Int(value)) mmHg")
        case .bloodOxygen:
            (value / 100).formatted(.percent.precision(.fractionLength(0)))
        }
    }

    nonisolated var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .heartRate: return "heart.fill"
        case .sleep: return "moon.fill"
        case .activeEnergy: return "flame.fill"
        case .distance: return "location.fill"
        case .weight: return "scalemass.fill"
        case .bloodPressure: return "heart.text.square.fill"
        case .bloodOxygen: return "drop.fill"
        }
    }

    nonisolated var color: String {
        switch self {
        case .steps: return "blue"
        case .heartRate: return "red"
        case .sleep: return "purple"
        case .activeEnergy: return "orange"
        case .distance: return "green"
        case .weight: return "brown"
        case .bloodPressure: return "pink"
        case .bloodOxygen: return "cyan"
        }
    }

    nonisolated var defaultUnit: String {
        switch self {
        case .steps: return "steps"
        case .heartRate: return "bpm"
        case .sleep: return "hours"
        case .activeEnergy: return "kcal"
        case .distance: return "km"
        case .weight: return "kg"
        case .bloodPressure: return "mmHg"
        case .bloodOxygen: return "%"
        }
    }
}
