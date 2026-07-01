//
//  FoundationLabApp.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import AppIntents
import FoundationLabCore
import FoundationModelsKit
import SwiftData

@main
struct FoundationLabApp: App {
    @State private var unavailabilityReason: FoundationModelAvailabilityUnavailableReason?
    @State private var showModelUnavailableWarning = false
#if os(macOS)
    @State private var agentBridgeController = AgentBridgeController()
#endif

    var body: some Scene {
        WindowGroup {
            AdaptiveNavigationView()
                .modelContainer(for: [HealthMetric.self, HealthSession.self])
#if os(macOS)
                .frame(
                    minWidth: FoundationLabLayout.macOSMinimumWindowWidth,
                    minHeight: FoundationLabLayout.macOSMinimumWindowHeight
                )
                .environment(agentBridgeController)
                .task {
                    agentBridgeController.activatePersistedPreference()
                }
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
        .defaultSize(
            width: FoundationLabLayout.macOSDefaultWindowWidth,
            height: FoundationLabLayout.macOSDefaultWindowHeight
        )
        .commands {
            SidebarCommands()
            InspectorCommands()
            FoundationLabNavigationCommands()
        }
#endif

#if os(macOS)
        Settings {
            SettingsView()
                .frame(minWidth: 520, minHeight: 420)
                .environment(agentBridgeController)
        }
#endif
    }

    private func checkModelAvailability() {
        let availability = FoundationModelAvailabilityUseCase().execute()
        if availability.isAvailable {
            showModelUnavailableWarning = false
        } else {
            unavailabilityReason = availability.reason
            showModelUnavailableWarning = true
        }
    }
}
