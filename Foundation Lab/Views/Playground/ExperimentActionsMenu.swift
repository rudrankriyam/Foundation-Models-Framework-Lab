//
//  ExperimentActionsMenu.swift
//  Foundation Lab
//

import SwiftUI

struct ExperimentActionsMenu: View {
    @Binding var isShowingDiscardConfirmation: Bool
    let requestNewExperiment: () -> Void
    let saveExperiment: () -> Void
    let discardAndCreate: () -> Void

    var body: some View {
        Menu("Experiment Actions", systemImage: "ellipsis.circle") {
            Button("New Experiment", systemImage: "plus", action: requestNewExperiment)
                .keyboardShortcut("n", modifiers: .command)
            Button("Save Experiment", systemImage: "square.and.arrow.down", action: saveExperiment)
                .keyboardShortcut("s", modifiers: .command)
        }
        .confirmationDialog(
            "Discard unsaved experiment?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard and Create New", role: .destructive, action: discardAndCreate)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save this experiment first if you want to keep its configuration.")
        }
    }
}
