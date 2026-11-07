//
//  ExperimentPreviewView.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct ExperimentPreviewView: View {
    let title: String
    let summary: String
    let configuration: FoundationLabExperimentConfiguration
    let openAccessibilityHint: LocalizedStringKey
    let open: () -> Void

    var body: some View {
        List {
            if !summary.isEmpty {
                Section {
                    Text(summary)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Experiment") {
                LabeledContent("Type") {
                    Text(LocalizedStringKey(configuration.kind.displayName))
                }
                LabeledContent("Runtime") {
                    Label {
                        Text(LocalizedStringKey(configuration.modelRuntime.displayName))
                    } icon: {
                        Image(systemName: configuration.modelRuntime.systemImage)
                    }
                }
            }

            if !configuration.prompt.isEmpty {
                Section("Prompt") {
                    Text(configuration.prompt)
                        .textSelection(.enabled)
                }
            }

            if !configuration.instructions.isEmpty {
                Section("Instructions") {
                    Text(configuration.instructions)
                        .textSelection(.enabled)
                }
            }

            RunToolsSection(tools: configuration.selectedTools)
        }
#if os(iOS)
        .listStyle(.insetGrouped)
#else
        .listStyle(.inset)
#endif
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Open in Playground", systemImage: "play.fill", action: open)
                    .accessibilityHint(openAccessibilityHint)
            }
        }
    }
}
