//
//  HealthDashboardView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import FoundationLabCore
import SwiftUI
import SwiftData

struct HealthDashboardView: View {
    @State private var showingBuddyChat = false
    @State private var isLoading = true
    @State private var loadErrorMessage: String?
    @State private var healthDataManager = HealthDataManager.shared
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.modelContext) private var modelContext

    @State private var todayMetrics: [MetricType: Double] = [:]
    @State private var encouragementMessage = "Loading today's summary..."
    @State private var isGeneratingMessage = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                if isLoading {
                    ProgressView("Loading health data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                } else if let loadErrorMessage {
                    healthDataUnavailableView(message: loadErrorMessage)
                } else {
                    headerSection
                    dailyProgressSection
                    metricsSection
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
            .padding()
        }
        .navigationTitle("Health Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingBuddyChat = true
                } label: {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .foregroundStyle(.primary)
                }
                .accessibilityLabel("Open Health AI chat")
            }
        }
        .sheet(isPresented: $showingBuddyChat) {
            HealthChatView()
        }
        .task {
            await loadHealthData()
        }
        .refreshable {
            await loadHealthData()
        }
    }

}

private extension HealthDashboardView {
    var headerSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        healthSummary
                        healthScore
                    }
                } else {
                    HStack {
                        healthSummary
                        Spacer()
                        healthScore
                    }
                }

                Text(encouragementMessage)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var healthSummary: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text("Good \(timeOfDay)!")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Today's progress across steps, sleep, and active energy")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var healthScore: some View {
        HealthScoreRing(score: calculateHealthScore())
            .frame(width: 80, height: 80)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Daily progress score")
            .accessibilityValue("\(Int(calculateHealthScore())) out of 100")
    }

    var dailyProgressSection: some View {
        GroupBox {
            VStack(spacing: Spacing.medium) {
                ForEach(Array(dailyMetricTypes.enumerated()), id: \.element) { index, type in
                    DailyProgressRow(
                        metricType: type,
                        currentValue: todayMetrics[type] ?? 0,
                        goalValue: type.defaultGoal
                    )

                    if index < dailyMetricTypes.count - 1 {
                        Divider()
                    }
                }
            }
        } label: {
            Label("Daily Progress", systemImage: "chart.bar.fill")
        }
    }

    var metricsSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(displayedMetricTypes.enumerated()), id: \.element) { index, type in
                    HealthMetricRow(
                        metricType: type,
                        value: todayMetrics[type] ?? 0
                    )

                    if index < displayedMetricTypes.count - 1 {
                        Divider()
                    }
                }
            }
        } label: {
            Label("Health Metrics", systemImage: "heart.text.square.fill")
        }
    }

    var dailyMetricTypes: [MetricType] {
        [.steps, .activeEnergy, .sleep]
    }

    var displayedMetricTypes: [MetricType] {
        [.steps, .heartRate, .sleep, .activeEnergy, .distance]
    }

    var timeOfDay: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return String(localized: "morning")
        case 12..<17: return String(localized: "afternoon")
        default: return String(localized: "evening")
        }
    }

    func calculateHealthScore() -> Double {
        let stepsScore = min((todayMetrics[.steps] ?? 0) / MetricType.steps.defaultGoal, 1.0)
        let sleepScore = min((todayMetrics[.sleep] ?? 0) / MetricType.sleep.defaultGoal, 1.0)
        let activityScore = min((todayMetrics[.activeEnergy] ?? 0) / MetricType.activeEnergy.defaultGoal, 1.0)

        return (stepsScore + sleepScore + activityScore) / 3.0 * 100
    }

    func healthDataUnavailableView(message: String) -> some View {
        ContentUnavailableView {
            Label("Health Data Unavailable", systemImage: "heart.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    await loadHealthData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
    }
}

@MainActor
private extension HealthDashboardView {
    func generateEncouragementMessage() async {
        guard !isGeneratingMessage else { return }
        isGeneratingMessage = true
        defer { isGeneratingMessage = false }

        let score = calculateHealthScore()
        let stepsProgress = (todayMetrics[.steps] ?? 0) / MetricType.steps.defaultGoal * 100
        let sleepHours = todayMetrics[.sleep] ?? 0
        let activeEnergy = Int(todayMetrics[.activeEnergy] ?? 0)

        do {
            let response = try await GenerateHealthEncouragementUseCase().execute(
                GenerateHealthEncouragementRequest(
                    healthScore: Int(score),
                    stepsProgressPercentage: Int(stepsProgress),
                    sleepHours: sleepHours,
                    activeEnergy: activeEnergy,
                    timeOfDay: timeOfDay,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            encouragementMessage = response.message
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\u{201C}", with: "")
                .replacingOccurrences(of: "\u{201D}", with: "")
        } catch {
            encouragementMessage = score >= 75
                ? String(localized: "Great progress today!")
                : String(localized: "Keep working towards your goals!")
        }

    }

    func loadHealthData() async {
        isLoading = true
        loadErrorMessage = nil
        healthDataManager.configureModelContext(modelContext)

        if !healthDataManager.isAuthorized {
            do {
                try await healthDataManager.requestAuthorization()
            } catch {
                loadErrorMessage = String(
                    localized: "Allow Health access in Settings, then try again. \(error.localizedDescription)"
                )
                isLoading = false
                return
            }
        }

        do {
            try await healthDataManager.fetchTodayHealthData()
        } catch {
            loadErrorMessage = String(
                localized: "Foundation Lab couldn't load Health data. \(error.localizedDescription)"
            )
            isLoading = false
            return
        }

        todayMetrics = [
            .steps: healthDataManager.todaySteps,
            .heartRate: healthDataManager.currentHeartRate,
            .sleep: healthDataManager.lastNightSleep,
            .activeEnergy: healthDataManager.todayActiveEnergy,
            .distance: healthDataManager.todayDistance
        ]

        isLoading = false

        await generateEncouragementMessage()
    }
}

// MARK: - Health Score Ring
struct HealthScoreRing: View {
    let score: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: 6)

            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(Int(score))")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)

                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - MetricType Extension
extension MetricType {
    var defaultGoal: Double {
        switch self {
        case .steps: return 10000
        case .heartRate: return 80
        case .sleep: return 8
        case .activeEnergy: return 500
        case .distance: return 5
        case .weight: return 70
        case .bloodPressure: return 120
        case .bloodOxygen: return 98
        }
    }
}

#Preview {
    NavigationStack {
        HealthDashboardView()
            .modelContainer(for: HealthMetric.self)
    }
}
