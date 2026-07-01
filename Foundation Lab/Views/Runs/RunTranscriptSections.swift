//
//  RunTranscriptSections.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct RunTranscriptSections: View {
    let run: FoundationLabExperimentRun

    var body: some View {
        Section("Transcript") {
            if run.events.isEmpty {
                Label("No transcript was recorded for this run", systemImage: "text.bubble")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(run.events) { event in
                    RunEventRowView(event: event)
                }
            }
        }

        if let errorMessage = run.errorMessage {
            Section("Error") {
                Label {
                    Text(errorMessage)
                        .textSelection(.enabled)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
        }

        if !run.configuration.instructions.isEmpty {
            Section("Instructions") {
                Text(run.configuration.instructions)
                    .textSelection(.enabled)
            }
        }
    }
}
