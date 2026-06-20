//
//  HealthExampleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
import SwiftData
#if os(iOS) && canImport(HealthKit)
import HealthKit
#endif

struct HealthExampleView: View {
    var body: some View {
        Group {
#if os(iOS) && canImport(HealthKit)
            if HKHealthStore.isHealthDataAvailable() {
                HealthDashboardView()
            } else {
                HealthUnavailableView()
            }
#else
            HealthUnavailableView()
#endif
        }
        .navigationTitle("Health Dashboard")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }
}

struct HealthUnavailableView: View {
    var body: some View {
        ContentUnavailableView {
            Label("Health Data Unavailable", systemImage: "heart.slash")
        } description: {
            Text("HealthKit is available on supported iPhone devices. Foundation Lab never invents missing measurements.")
        }
    }
}

#Preview {
    HealthExampleView()
        .modelContainer(for: [HealthMetric.self, HealthSession.self])
}
