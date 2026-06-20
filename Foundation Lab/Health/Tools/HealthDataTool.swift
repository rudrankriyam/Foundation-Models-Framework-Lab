//
//  HealthDataTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import SwiftData
import SwiftUI

struct HealthDataTool: Tool {
    let name = "fetchHealthData"
    let description = "Fetch current health data including steps, heart rate, sleep, and other metrics"

    @Generable
    struct Arguments {
        @Guide(
            description: """
            The type of health data to fetch: 'today', 'weekly', or specific metric like 'steps', 'heartRate',
            'sleep', 'activeEnergy', 'distance'
            """
        )
        var dataType: String

        @Guide(description: "Whether to fetch from HealthKit (true) or SwiftData cache (false). Defaults to false.")
        var refreshFromHealthKit: Bool?
    }

    func call(arguments: Arguments) async throws -> some PromptRepresentable {
        // Validate input
        let dataType = arguments.dataType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !dataType.isEmpty else {
            return createErrorOutput(error: "Data type cannot be empty. Please specify 'today', 'weekly', or a specific metric.")
        }

        let healthManager = await MainActor.run { HealthDataManager.shared }
        let refreshFlag = arguments.refreshFromHealthKit ?? false

        switch dataType.lowercased() {
        case "today":
            return await fetchTodayData(healthManager: healthManager, refresh: refreshFlag)
        case "weekly":
            return await fetchWeeklyData(healthManager: healthManager)
        case "steps":
            return await fetchSpecificMetric(
                healthManager: healthManager,
                type: .steps,
                refresh: refreshFlag
            )
        case "heartrate":
            return await fetchSpecificMetric(
                healthManager: healthManager,
                type: .heartRate,
                refresh: refreshFlag
            )
        case "sleep":
            return await fetchSpecificMetric(
                healthManager: healthManager,
                type: .sleep,
                refresh: refreshFlag
            )
        case "activeenergy":
            return await fetchSpecificMetric(
                healthManager: healthManager,
                type: .activeEnergy,
                refresh: refreshFlag
            )
        case "distance":
            return await fetchSpecificMetric(
                healthManager: healthManager,
                type: .distance,
                refresh: refreshFlag
            )
        default:
            let message = """
            Invalid data type. Use 'today', 'weekly', 'steps', 'heartRate', 'sleep', 'activeEnergy', or 'distance'.
            """
            return createErrorOutput(error: message)
        }
    }

    private func fetchTodayData(healthManager: HealthDataManager, refresh: Bool) async -> GeneratedContent {
        if refresh {
            do {
                try await healthManager.fetchTodayHealthData()
            } catch {
                return createErrorOutput(error: error.localizedDescription)
            }
        }

        let metricsJSON = await MainActor.run {
            """
            {
                "steps": \(Int(healthManager.todaySteps)),
                "activeEnergy": \(Int(healthManager.todayActiveEnergy)),
                "distance": \(String(format: "%.2f", healthManager.todayDistance)),
                "heartRate": \(Int(healthManager.currentHeartRate)),
                "sleep": \(String(format: "%.1f", healthManager.lastNightSleep))
            }
            """
        }

        return GeneratedContent(properties: [
            "status": "success",
            "dataType": "today",
            "metrics": metricsJSON,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "message": "Today's health data retrieved successfully"
        ])
    }

    private func fetchWeeklyData(healthManager: HealthDataManager) async -> GeneratedContent {
        let weeklyData = await healthManager.fetchWeeklyData()

        var weeklyStatsArray: [String] = []

        for (metric, dailyData) in weeklyData {
            let values = dailyData.map { $0.value }
            let total = values.reduce(0, +)
            let average = values.isEmpty ? 0 : total / Double(values.count)

            weeklyStatsArray.append("""
                "\(metric.rawValue)": {
                    "total": \(String(format: "%.0f", total)),
                    "average": \(String(format: "%.1f", average)),
                    "days": \(values.count)
                }
                """)
        }

        let weeklyStatsJSON = "{\(weeklyStatsArray.joined(separator: ","))}"

        return GeneratedContent(properties: [
            "status": "success",
            "dataType": "weekly",
            "weeklyStats": weeklyStatsJSON,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "message": "Weekly health data retrieved successfully"
        ])
    }

    private func fetchSpecificMetric(
        healthManager: HealthDataManager,
        type: MetricType,
        refresh: Bool
    ) async -> GeneratedContent {
        if refresh {
            do {
                try await healthManager.fetchTodayHealthData()
            } catch {
                return createErrorOutput(error: error.localizedDescription)
            }
        }

        let value: Double = await MainActor.run {
            switch type {
            case .steps:
                return healthManager.todaySteps
            case .heartRate:
                return healthManager.currentHeartRate
            case .sleep:
                return healthManager.lastNightSleep
            case .activeEnergy:
                return healthManager.todayActiveEnergy
            case .distance:
                return healthManager.todayDistance
            default:
                return 0.0
            }
        }

        if type.rawValue == "unsupported" {
            return createErrorOutput(error: "Metric type not supported")
        }

        return GeneratedContent(properties: [
            "status": "success",
            "metric": type.rawValue,
            "value": value,
            "unit": type.defaultUnit,
            "icon": type.icon,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "message": "\(type.rawValue): \(formatValue(value, for: type))"
        ])
    }

    nonisolated private func formatValue(_ value: Double, for type: MetricType) -> String {
        switch type {
        case .steps, .activeEnergy:
            return "\(Int(value))"
        case .heartRate:
            return "\(Int(value)) bpm"
        case .sleep:
            return String(format: "%.1f hours", value)
        case .distance:
            return String(format: "%.2f km", value)
        default:
            return String(format: "%.1f", value)
        }
    }

    private func createErrorOutput(error: String) -> GeneratedContent {
        return GeneratedContent(properties: [
            "status": "error",
            "error": error,
            "message": "Failed to fetch health data"
        ])
    }
}
