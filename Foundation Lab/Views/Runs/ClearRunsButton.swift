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
                "Delete All Runs",
                systemImage: "trash",
                role: .destructive,
                action: showConfirmation
            )
        }
        .confirmationDialog(
            "Delete all run history?",
            isPresented: $isShowingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All Runs", role: .destructive, action: store.clearRuns)
        } message: {
            Text("This permanently deletes every recorded run. Saved experiments are not affected.")
        }
        .accessibilityHint("Contains actions for managing all saved runs")
    }

    private func showConfirmation() {
        isShowingConfirmation = true
    }
}
