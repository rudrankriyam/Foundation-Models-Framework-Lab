//
//  RunDetailColumn.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RunDetailColumn: View {
    let runID: FoundationLabExperimentRun.ID?

    @Environment(ExperimentStore.self) private var store

    var body: some View {
        if let run = store.runs.first(where: { $0.id == runID }) {
            RunDetailView(run: run)
        } else {
            ContentUnavailableView(
                "No Run Selected",
                systemImage: "clock.arrow.circlepath",
                description: Text("Select a run to see its output, timing, and exact configuration.")
            )
        }
    }
}
