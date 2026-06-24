//
//  WorkspaceView.swift
//  Foundation Lab
//

import SwiftUI

struct WorkspaceView: View {
    let workspace: Workspace

    @AppStorage private var selectedStageRawValue: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

#if os(macOS)
    @State private var adapterStudioViewModel = AdapterStudioViewModel()
#endif

    init(workspace: Workspace) {
        self.workspace = workspace
        _selectedStageRawValue = AppStorage(
            wrappedValue: WorkspaceStage.settings.rawValue,
            FoundationLabPreferenceKey.workspaceStage(for: workspace)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            stagePicker
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xLarge) {
                    workspaceHeader
                    workspaceContent
                }
                .padding(.horizontal, Spacing.xxLarge)
                .padding(.vertical, Spacing.xLarge)
                .frame(maxWidth: FoundationLabLayout.workspaceContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(workspace.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#else
        .navigationSubtitle(workspace.summary)
#endif
    }

    @ViewBuilder
    private var stagePicker: some View {
        if horizontalSizeClass == .compact || dynamicTypeSize.isAccessibilitySize {
            Picker("Stage", selection: $selectedStageRawValue) {
                stages
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
            .background(.bar)
        } else {
            Picker("Stage", selection: $selectedStageRawValue) {
                stages
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 640)
            .padding(.horizontal, Spacing.xLarge)
            .padding(.vertical, Spacing.small)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.bar)
        }
    }

    private var stages: some View {
        ForEach(WorkspaceStage.allCases) { stage in
            Label(workspace.title(for: stage), systemImage: workspace.systemImage(for: stage))
                .tag(stage.rawValue)
        }
    }

    private var workspaceHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Label(workspace.title, systemImage: workspace.systemImage)
                .font(.title2.bold())

            Text(workspace.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var workspaceContent: some View {
        let selectedStage = WorkspaceStage(rawValue: selectedStageRawValue) ?? .settings
        switch workspace {
        case .adapterComparison:
#if os(macOS)
            AdapterStudioContent(
                stage: selectedStage,
                viewModel: adapterStudioViewModel
            )
#else
            AdapterStudioContent(stage: selectedStage)
#endif
        case .fmfBench:
            FMFBenchStudioContent(stage: selectedStage)
        }
    }
}

#Preview {
    NavigationStack {
        WorkspaceView(workspace: .fmfBench)
    }
}
