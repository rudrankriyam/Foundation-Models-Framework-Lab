//
//  HealthKitService.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/20/25.
//

import Foundation
import HealthKit
import OSLog

// swiftlint:disable type_body_length
actor HealthKitService {
    private let healthStore: HKHealthStore?
    private let logger = VoiceLogging.health

    private let metersToKilometers: Double = 1000.0
    private let secondsToHours: Double = 3600.0

    var isAuthorized: Bool = false

    init() {
        #if os(iOS)
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
        }
        #else
        self.healthStore = nil
        #endif
    }

    func requestAuthorization() async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.unavailable
        }

        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let distanceType = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate),
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typesUnavailable
        }

        let readTypes: Set<HKObjectType> = [
            stepCountType,
            activeEnergyType,
            distanceType,
            heartRateType,
            sleepType,
            HKObjectType.workoutType()
        ]

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)

        // HealthKit intentionally does not reveal read authorization. The
        // sharing status APIs only describe permission to save samples, and
        // this app requests read-only access. A successful request means
        // queries may proceed; denied types simply return no matching data.
        isAuthorized = true
    }

    func fetchAllTodayMetrics() async -> TodayHealthMetrics {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = Date()

        async let steps = fetchSteps(from: startOfDay, to: endOfDay)
        async let activeEnergy = fetchActiveEnergy(from: startOfDay, to: endOfDay)
        async let distance = fetchDistance(from: startOfDay, to: endOfDay)
        async let heartRate = fetchLatestHeartRate()
        async let sleep = fetchLastNightSleep()

        return await TodayHealthMetrics(
            steps: steps,
            activeEnergy: activeEnergy,
            distance: distance,
            heartRate: heartRate,
            sleep: sleep
        )
    }

    func fetchWeeklyData() async -> [MetricType: [DailyMetricData]] {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) else {
            logger.error("Failed to calculate start date for weekly data")
            return [:]
        }

        var weeklyData: [MetricType: [DailyMetricData]] = [:]

        for metricType in [MetricType.steps, .activeEnergy, .sleep] {
            weeklyData[metricType] = await fetchDailyData(for: metricType, from: startDate, to: endDate)
        }

        return weeklyData
    }

    func fetchSteps(from startDate: Date, to endDate: Date) async -> Double? {
        await fetchQuantityData(
            quantityTypeIdentifier: .stepCount,
            unit: HKUnit.count(),
            from: startDate,
            to: endDate
        )
    }

    func fetchActiveEnergy(from startDate: Date, to endDate: Date) async -> Double? {
        await fetchQuantityData(
            quantityTypeIdentifier: .activeEnergyBurned,
            unit: .kilocalorie(),
            from: startDate,
            to: endDate
        )
    }

    func fetchDistance(from startDate: Date, to endDate: Date) async -> Double? {
        await fetchQuantityData(
            quantityTypeIdentifier: .distanceWalkingRunning,
            unit: .meter(),
            from: startDate,
            to: endDate
        )
        .map { $0 / metersToKilometers }
    }

    func fetchLatestHeartRate() async -> Double? {
        guard let healthStore = healthStore,
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }

        let descriptor = HKSampleQueryDescriptor(
            predicates: [HKSamplePredicate.quantitySample(type: heartRateType)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .reverse)],
            limit: 1
        )

        do {
            let samples = try await descriptor.result(for: healthStore)
            if let sample = samples.first {
                let unit = HKUnit.count().unitDivided(by: .minute())
                return sample.quantity.doubleValue(for: unit)
            }
        } catch {
            logger.error("Failed to fetch heart rate data: \(error.localizedDescription)")
        }

        return nil
    }

    func fetchLastNightSleep() async -> Double? {
        guard let healthStore = healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) else {
            logger.error("Failed to calculate start date for sleep data")
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            let sleepSamples = try await descriptor.result(for: healthStore)
            return totalAsleepDuration(in: sleepSamples).map { $0 / secondsToHours }
        } catch {
            logger.error("Failed to fetch sleep data: \(error.localizedDescription)")
        }

        return nil
    }

    private func fetchQuantityData(
        quantityTypeIdentifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        from startDate: Date,
        to endDate: Date
    ) async -> Double? {
        guard let healthStore = healthStore,
              let quantityType = HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier) else {
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.quantitySample(type: quantityType, predicate: predicate)

        let descriptor = HKStatisticsQueryDescriptor(
            predicate: samplePredicate,
            options: .cumulativeSum
        )

        do {
            let result = try await descriptor.result(for: healthStore)
            if let sum = result?.sumQuantity() {
                return sum.doubleValue(for: unit)
            }
        } catch {
            logger.error("Failed to fetch \(quantityTypeIdentifier.rawValue) data: \(error.localizedDescription)")
        }

        return nil
    }

    private func fetchDailyData(
        for metricType: MetricType,
        from startDate: Date,
        to endDate: Date
    ) async -> [DailyMetricData] {
        var dailyData: [DailyMetricData] = []
        let calendar = Calendar.current

        var currentDate = startDate
        while currentDate <= endDate {
            let dayStart = calendar.startOfDay(for: currentDate)
            guard let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else {
                logger.error("Failed to calculate day end date")
                break
            }

            let value: Double?
            switch metricType {
            case .steps:
                value = await fetchQuantityData(
                    quantityTypeIdentifier: .stepCount,
                    unit: HKUnit.count(),
                    from: dayStart,
                    to: dayEnd
                )
            case .activeEnergy:
                value = await fetchQuantityData(
                    quantityTypeIdentifier: .activeEnergyBurned,
                    unit: .kilocalorie(),
                    from: dayStart,
                    to: dayEnd
                )
            case .sleep:
                value = await fetchSleepValue(for: dayStart)
            default:
                value = nil
            }

            dailyData.append(DailyMetricData(date: currentDate, value: value))
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                logger.error("Failed to calculate next date")
                break
            }
            currentDate = nextDate
        }

        return dailyData
    }

    private func fetchSleepValue(for date: Date) async -> Double? {
        guard let healthStore = healthStore,
              let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }

        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: date)
        guard let startDate = calendar.date(byAdding: .day, value: -1, to: endDate) else {
            logger.error("Failed to calculate start date for sleep value")
            return nil
        }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let samplePredicate = HKSamplePredicate.categorySample(type: sleepType, predicate: predicate)

        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            let sleepSamples = try await descriptor.result(for: healthStore)
            return totalAsleepDuration(in: sleepSamples).map { $0 / secondsToHours }
        } catch {
            logger.error("Failed to fetch sleep value: \(error.localizedDescription)")
        }

        return nil
    }

    private func totalAsleepDuration(in samples: [HKCategorySample]) -> TimeInterval? {
        let intervals = samples.compactMap { sample -> DateInterval? in
            guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value),
                  HKCategoryValueSleepAnalysis.allAsleepValues.contains(value),
                  sample.endDate > sample.startDate else {
                return nil
            }
            return DateInterval(start: sample.startDate, end: sample.endDate)
        }
        .sorted { $0.start < $1.start }

        guard var activeInterval = intervals.first else { return nil }

        var duration: TimeInterval = 0
        for interval in intervals.dropFirst() {
            if interval.start <= activeInterval.end {
                activeInterval = DateInterval(
                    start: activeInterval.start,
                    end: max(activeInterval.end, interval.end)
                )
            } else {
                duration += activeInterval.duration
                activeInterval = interval
            }
        }
        return duration + activeInterval.duration
    }
}
// swiftlint:enable type_body_length

// MARK: - Supporting Types

struct TodayHealthMetrics {
    let steps: Double?
    let activeEnergy: Double?
    let distance: Double?
    let heartRate: Double?
    let sleep: Double?
}

enum HealthKitError: LocalizedError {
    case unavailable
    case typesUnavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return String(localized: "HealthKit isn’t available on this device.")
        case .typesUnavailable:
            return String(localized: "The requested HealthKit data types aren’t available on this device.")
        }
    }
}

struct DailyMetricData {
    let date: Date
    let value: Double?
}
