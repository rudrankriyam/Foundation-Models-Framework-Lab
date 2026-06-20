//
//  HealthDataManager.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class HealthDataManager {
    // MARK: - Services

    let healthKitService: HealthKitService
    private(set) var healthRepository: HealthRepository

    // MARK: - Observable State

    var isAuthorized: Bool = false
    private(set) var todaySteps: Double?
    private(set) var todayActiveEnergy: Double?
    private(set) var todayDistance: Double?
    private(set) var currentHeartRate: Double?
    private(set) var lastNightSleep: Double?

    var currentMetrics: [MetricType: Double] {
        var metrics: [MetricType: Double] = [:]
        metrics[.steps] = todaySteps
        metrics[.activeEnergy] = todayActiveEnergy
        metrics[.distance] = todayDistance
        metrics[.heartRate] = currentHeartRate
        metrics[.sleep] = lastNightSleep
        return metrics
    }

    // MARK: - Initialization

    init() {
        self.healthKitService = HealthKitService()
        self.healthRepository = HealthRepository()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws {
        try await healthKitService.requestAuthorization()
        isAuthorized = await healthKitService.isAuthorized
    }

    // MARK: - Fetch Today's Data

    func fetchTodayHealthData() async throws {
        guard isAuthorized else {
            throw HealthDataManagerError.notAuthorized
        }

        let metrics = await healthKitService.fetchAllTodayMetrics()

        todaySteps = metrics.steps
        todayActiveEnergy = metrics.activeEnergy
        todayDistance = metrics.distance
        currentHeartRate = metrics.heartRate
        lastNightSleep = metrics.sleep

        // Persist only actual positive samples; absence stays distinct from zero.
        let metricsToSave = currentMetrics.filter { $0.value > 0 }
        healthRepository.saveMetrics(metricsToSave)
    }

    // MARK: - Fetch Weekly Data

    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        await healthKitService.fetchWeeklyData()
    }

    // MARK: - SwiftData Context

    func configureModelContext(_ context: ModelContext) {
        healthRepository.setModelContext(context)
    }

    // MARK: - Fetch Recent Metrics

    func fetchRecentMetrics(days: Int = 7) -> [HealthMetric] {
        healthRepository.fetchRecentMetrics(days: days)
    }
}

// MARK: - Singleton Instance

extension HealthDataManager {
    static let shared = HealthDataManager()
}

// MARK: - Errors

enum HealthDataManagerError: LocalizedError {
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return String(localized: "HealthKit authorization is required to fetch health data")
        }
    }
}
