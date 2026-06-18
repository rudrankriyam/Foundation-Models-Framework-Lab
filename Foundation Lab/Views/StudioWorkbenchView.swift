//
//  StudioWorkbenchView.swift
//  Foundation Lab
//

import SwiftUI

struct StudioWorkbenchView<Content: View, Inspector: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Binding var workspace: StudioWorkspace
    @Binding var stage: StudioPipelineStage

    let isRunning: Bool
    let canRun: Bool
    let run: () -> Void
    let content: Content
    let inspector: Inspector

    var body: some View {
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            workbenchLayout
        }
    }

    private var workbenchLayout: some View {
        Group {
#if os(macOS)
            ViewThatFits(in: .horizontal) {
                HSplitView {
                    primaryColumn
                        .frame(minWidth: 600, idealWidth: 820, maxWidth: .infinity, maxHeight: .infinity)
                        .layoutPriority(1)

                    inspectorColumn
                        .frame(minWidth: 260, idealWidth: 300, maxWidth: 340)
                }

                narrowLayout
            }
#else
            HStack(spacing: 0) {
                StudioSourceList(selectedWorkspace: $workspace)
                .frame(width: 240)

                Divider()

                primaryColumn
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
#endif
        }
    }

    private var primaryColumn: some View {
        VStack(spacing: 0) {
            stageBar(isCompact: false)
            Divider()
            mainWorkspace
        }
    }

    private var narrowLayout: some View {
        VStack(spacing: 0) {
            stageBar(isCompact: false)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    workspaceHeader
                    content
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 0) {
            stageBar(isCompact: true)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    compactWorkspacePicker
                    content
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var mainWorkspace: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xLarge) {
                workspaceHeader
                content
            }
            .padding(.horizontal, Spacing.xxLarge)
            .padding(.vertical, Spacing.xLarge)
            .frame(maxWidth: 960, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(workspace.title)
                .font(.title2.bold())

            Text(workspace.subtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var compactWorkspacePicker: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Picker("Workspace", selection: $workspace) {
                ForEach(StudioWorkspace.allCases) { workspace in
                    Label(workspace.title, systemImage: workspace.icon)
                        .tag(workspace)
                }
            }
            .pickerStyle(.menu)

            Text(workspace.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inspectorColumn: some View {
        VStack(spacing: 0) {
            inspector
            Spacer(minLength: 0)
        }
        .background(.background)
    }

    private func stageBar(isCompact: Bool) -> some View {
        StudioStageBar(
            workspace: $workspace,
            stage: $stage,
            isCompact: isCompact,
            isRunning: isRunning,
            canRun: canRun,
            run: run
        )
    }
}
