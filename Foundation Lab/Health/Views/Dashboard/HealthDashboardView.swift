//
//  HealthDashboardView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData

struct HealthDashboardView: View {
    @State private var isShowingHealthChat = false
    @State private var isLoading = true
    @State private var loadErrorMessage: String?
    @State private var healthDataManager = HealthDataManager.shared
    @Environment(\.modelContext) private var modelContext

    @State private var todayMetrics: [MetricType: Double] = [:]

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

                    if todayMetrics.isEmpty {
                        ContentUnavailableView(
                            "No Health Data Available",
                            systemImage: "heart.slash",
                            description: Text(
                                "HealthKit did not return any of the requested measurements. Missing data is never estimated."
                            )
                        )
                        .frame(maxWidth: .infinity, minHeight: 240)
                    } else {
                        metricsSection
                    }
                }
            }
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Health")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Ask About Health Data", systemImage: "bubble.left.and.bubble.right") {
                    isShowingHealthChat = true
                }
                .disabled(isLoading)
            }
        }
        .sheet(isPresented: $isShowingHealthChat) {
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
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.title2.weight(.semibold))
            Text("Measurements returned by HealthKit for this device. Missing values stay unavailable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    var metricsSection: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(displayedMetricTypes.enumerated()), id: \.element) { index, type in
                    HealthMetricRow(
                        metricType: type,
                        value: todayMetrics[type]
                    )

                    if index < displayedMetricTypes.count - 1 {
                        Divider()
                    }
                }
            }
        } label: {
            Label("Available Today", systemImage: "heart.text.square")
        }
    }

    var displayedMetricTypes: [MetricType] {
        [.steps, .heartRate, .sleep, .activeEnergy, .distance]
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

        todayMetrics = healthDataManager.currentMetrics

        isLoading = false
    }
}

#Preview {
    NavigationStack {
        HealthDashboardView()
            .modelContainer(for: HealthMetric.self)
    }
}
