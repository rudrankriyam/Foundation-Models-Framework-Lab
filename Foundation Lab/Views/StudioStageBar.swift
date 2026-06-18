//
//  StudioStageBar.swift
//  Foundation Lab
//

import SwiftUI

struct StudioStageBar: View {
    @Binding var workspace: StudioWorkspace
    @Binding var stage: StudioPipelineStage

    let isCompact: Bool
    let isRunning: Bool
    let canRun: Bool
    let run: () -> Void

    var body: some View {
        if isCompact {
            compactBar
        } else {
            regularBar
        }
    }

    private var regularBar: some View {
        HStack(spacing: Spacing.large) {
#if os(macOS)
            Picker("Workspace", selection: $workspace) {
                ForEach(StudioWorkspace.allCases) { workspace in
                    Label(workspace.title, systemImage: workspace.icon)
                        .tag(workspace)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 220)
#endif

            Picker("Stage", selection: $stage) {
                ForEach(StudioPipelineStage.allCases) { stage in
                    Label(stage.title, systemImage: stage.systemImage)
                        .tag(stage)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 560)

            Spacer(minLength: 0)

#if os(macOS)
            if workspace == .promptTesting {
                Button(
                    "Run",
                    systemImage: isRunning ? "hourglass" : "play.fill",
                    action: run
                )
                .buttonStyle(.borderedProminent)
                .disabled(isRunning || !canRun)
                .help("Run selected prompt variants")
            }
#endif
        }
        .padding(.horizontal, Spacing.xLarge)
        .padding(.vertical, Spacing.small)
        .background(.bar)
    }

    private var compactBar: some View {
        Picker("Stage", selection: $stage) {
            ForEach(StudioPipelineStage.allCases) { stage in
                Label(stage.title, systemImage: stage.systemImage)
                    .tag(stage)
            }
        }
        .pickerStyle(.menu)
        .labelsHidden()
        .accessibilityLabel("Stage")
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.medium)
        .frame(minHeight: 44)
        .background(.bar)
    }
}
