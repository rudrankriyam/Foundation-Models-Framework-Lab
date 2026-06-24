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
            "Create a new experiment?",
            isPresented: $isShowingDiscardConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard Changes and Create New", role: .destructive, action: discardAndCreate)
            Button("Keep Editing", role: .cancel) {}
        } message: {
            Text("Unsaved changes to this experiment will be lost.")
        }
    }
}
