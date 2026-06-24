//
//  HealthDataTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import FoundationModels
import FoundationModelsKit
import SwiftData
import SwiftUI

struct HealthDataTool: Tool {
    let name = "fetchHealthData"
    let description = "Read authorized HealthKit measurements for today, this week, or a specific metric"

    @Generable
    struct Arguments: RuntimeCompatibleGenerable {
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
            return createErrorOutput(error: "Choose today, weekly, steps, heartRate, sleep, activeEnergy, or distance.")
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
}

private extension HealthDataTool {
    private func fetchTodayData(healthManager: HealthDataManager, refresh: Bool) async -> GeneratedContent {
        if refresh {
            do {
                try await healthManager.fetchTodayHealthData()
            } catch {
                return createErrorOutput(error: error.localizedDescription)
            }
        }

        let metricValues = await MainActor.run {
            (
                healthManager.todaySteps,
                healthManager.todayActiveEnergy,
                healthManager.todayDistance,
                healthManager.currentHeartRate,
                healthManager.lastNightSleep
            )
        }
        let metricsJSON = """
        {
            "steps": \(jsonNumber(metricValues.0)),
            "activeEnergy": \(jsonNumber(metricValues.1)),
            "distance": \(jsonNumber(metricValues.2)),
            "heartRate": \(jsonNumber(metricValues.3)),
            "sleep": \(jsonNumber(metricValues.4))
        }
        """
        let availableMetricCount = [
            metricValues.0,
            metricValues.1,
            metricValues.2,
            metricValues.3,
            metricValues.4
        ].compactMap { $0 }.count
        let status: String
        let message: String
        if availableMetricCount == 0 {
            status = "unavailable"
            message = "No readable health measurements were returned"
        } else if availableMetricCount < 5 {
            status = "partial"
            message = "\(availableMetricCount) of 5 requested health measurements were available"
        } else {
            status = "success"
            message = "All requested HealthKit measurements were available"
        }

        return GeneratedContent(properties: [
            "status": status,
            "dataType": "today",
            "metrics": metricsJSON,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "message": message
        ])
    }

    private func fetchWeeklyData(healthManager: HealthDataManager) async -> GeneratedContent {
        let weeklyData = await healthManager.fetchWeeklyData()

        var weeklyStatsArray: [String] = []
        var availableDayCount = 0
        var requestedDayCount = 0

        for (metric, dailyData) in weeklyData {
            let values = dailyData.compactMap(\.value)
            availableDayCount += values.count
            requestedDayCount += dailyData.count
            let total = values.reduce(0, +)
            let average = values.isEmpty ? nil : total / Double(values.count)

            weeklyStatsArray.append("""
                "\(metric.rawValue)": {
                    "total": \(values.isEmpty ? "null" : jsonNumber(total)),
                    "average": \(jsonNumber(average)),
                    "days": \(values.count)
                }
                """)
        }

        let weeklyStatsJSON = "{\(weeklyStatsArray.joined(separator: ","))}"
        let status: String
        let message: String
        if availableDayCount == 0 {
            status = "unavailable"
            message = "No readable weekly health samples were returned"
        } else if availableDayCount < requestedDayCount {
            status = "partial"
            message = "Health data was available for \(availableDayCount) of \(requestedDayCount) daily samples"
        } else {
            status = "success"
            message = "All requested weekly HealthKit samples were available"
        }

        return GeneratedContent(properties: [
            "status": status,
            "dataType": "weekly",
            "weeklyStats": weeklyStatsJSON,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "message": message
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

        let value: Double? = await MainActor.run {
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
                return nil
            }
        }

        guard let value else {
            return GeneratedContent(properties: [
                "status": "unavailable",
                "metric": type.rawValue,
                "unit": type.defaultUnit,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "message": "No readable \(type.rawValue) measurement was returned"
            ])
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
            return value.formatted(.number.precision(.fractionLength(1))) + " hours"
        case .distance:
            return value.formatted(.number.precision(.fractionLength(2))) + " km"
        default:
            return value.formatted(.number.precision(.fractionLength(1)))
        }
    }

    nonisolated private func jsonNumber(_ value: Double?) -> String {
        guard let value,
              let data = try? JSONEncoder().encode(value),
              let encodedValue = String(data: data, encoding: .utf8) else {
            return "null"
        }
        return encodedValue
    }

    private func createErrorOutput(error: String) -> GeneratedContent {
        return GeneratedContent(properties: [
            "status": "error",
            "error": error,
            "message": "HealthKit data could not be read"
        ])
    }
}
