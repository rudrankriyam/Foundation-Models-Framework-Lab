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
