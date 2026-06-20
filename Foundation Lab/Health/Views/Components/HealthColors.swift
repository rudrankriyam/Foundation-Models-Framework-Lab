//
//  HealthColors.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI

/// Health-themed color palette for FoundationLab
extension Color {
    // MARK: - Primary Health Colors
    static let healthPrimary = Color(red: 0.0, green: 0.78, blue: 0.88) // Bright cyan
    static let healthSecondary = Color(red: 0.44, green: 0.86, blue: 0.58) // Fresh green
    static let healthAccent = Color(red: 1.0, green: 0.45, blue: 0.42) // Warm coral

    // MARK: - Metric-Specific Colors
    static let heartColor = Color(red: 0.91, green: 0.12, blue: 0.31) // Heart red
    static let stepsColor = Color(red: 0.0, green: 0.48, blue: 1.0) // Activity blue
    static let sleepColor = Color(red: 0.58, green: 0.39, blue: 0.87) // Sleep purple
    static let caloriesColor = Color(red: 1.0, green: 0.58, blue: 0.0) // Energy orange
    static let mindfulnessColor = Color(red: 0.0, green: 0.73, blue: 0.62) // Calm teal

    // MARK: - Status Colors
    static let successGreen = Color(red: 0.2, green: 0.78, blue: 0.35)
    static let warningYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let alertRed = Color(red: 0.91, green: 0.26, blue: 0.21)

    // MARK: - Background Colors
    static var adaptiveBackground: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #elseif os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }

    static let lightBackground = Color(red: 0.97, green: 0.98, blue: 0.99)
    static let darkBackground = Color(red: 0.11, green: 0.11, blue: 0.14)

    // MARK: - Glass Tint Colors
    static let glassTintLight = Color.white.opacity(0.3)
    static let glassTintDark = Color.black.opacity(0.2)
}

/// Gradient presets for health metrics
extension LinearGradient {
    @MainActor static let healthGradient = LinearGradient(
        colors: [.healthPrimary, .healthSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @MainActor static let heartGradient = LinearGradient(
        colors: [.heartColor, .heartColor.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    @MainActor static let activityGradient = LinearGradient(
        colors: [.stepsColor, .stepsColor.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    @MainActor static let sleepGradient = LinearGradient(
        colors: [.sleepColor.opacity(0.8), .sleepColor],
        startPoint: .top,
        endPoint: .bottom
    )

    @MainActor static let energyGradient = LinearGradient(
        colors: [.caloriesColor, .caloriesColor.opacity(0.7)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Helper to get metric-specific colors
extension MetricType {
    var themeColor: Color {
        switch self {
        case .steps: return .stepsColor
        case .heartRate: return .heartColor
        case .sleep: return .sleepColor
        case .activeEnergy: return .caloriesColor
        case .distance: return .healthSecondary
        case .weight: return Color.brown
        case .bloodPressure: return .heartColor.opacity(0.8)
        case .bloodOxygen: return Color.cyan
        }
    }

    var gradient: LinearGradient {
        switch self {
        case .steps: return .activityGradient
        case .heartRate: return .heartGradient
        case .sleep: return .sleepGradient
        case .activeEnergy: return .energyGradient
        default: return .healthGradient
        }
    }
}
