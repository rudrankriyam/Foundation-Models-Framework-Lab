//
//  FoundationLabApp.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import AppIntents
import FoundationLabCore
import SwiftData

@main
struct FoundationLabApp: App {
    @State private var unavailabilityReason: ModelAvailabilityUnavailableReason?
    @State private var showModelUnavailableWarning = false

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .modelContainer(for: [HealthMetric.self, HealthInsight.self, HealthSession.self])
#if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
#endif
                .onAppear {
                    FoundationLabAppShortcuts.updateAppShortcutParameters()
                    checkModelAvailability()
                }
                .tint(.main)
                .sheet(isPresented: $showModelUnavailableWarning) {
                    ModelUnavailableView(reason: unavailabilityReason)
                }
        }
#if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 520, minHeight: 420)
        }
#endif
    }

    private func checkModelAvailability() {
        let availability = CheckModelAvailabilityUseCase().execute()
        if availability.isAvailable {
            showModelUnavailableWarning = false
        } else {
            unavailabilityReason = availability.reason
            showModelUnavailableWarning = true
        }
    }
}
