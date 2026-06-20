//
//  ClearRunsButton.swift
//  Foundation Lab
//

import SwiftUI

struct ClearRunsButton: View {
    @Environment(ExperimentStore.self) private var store
    @State private var isShowingConfirmation = false

    var body: some View {
        Menu("Run History Actions", systemImage: "ellipsis.circle") {
            Button(
                "Clear All Runs",
                systemImage: "trash",
                role: .destructive,
                action: showConfirmation
            )
        }
        .confirmationDialog(
            "Clear all run history?",
            isPresented: $isShowingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear All Runs", role: .destructive, action: store.clearRuns)
        } message: {
            Text("This removes every saved result. Your experiments are not affected.")
        }
        .accessibilityHint("Contains actions for managing all saved runs")
    }

    private func showConfirmation() {
        isShowingConfirmation = true
    }
}
