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
                    WorkspacePhaseHeader(
                        workspace: workspace,
                        stage: selectedStage
                    )
                    workspaceContent
                }
                .padding(.horizontal, Spacing.xxLarge)
                .padding(.vertical, Spacing.xLarge)
                .frame(maxWidth: FoundationLabLayout.workspaceContentWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            WorkspaceStatusRail(
                title: workspaceStatusTitle,
                context: workspace.title(for: selectedStage),
                systemImage: workspaceStatusSystemImage,
                isActive: workspaceStatusIsActive
            )
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
            Picker("Phase", selection: $selectedStageRawValue) {
                stages
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
            .background(.bar)
        } else {
            Picker("Phase", selection: $selectedStageRawValue) {
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

    private var selectedStage: WorkspaceStage {
        WorkspaceStage(rawValue: selectedStageRawValue) ?? .settings
    }

    @ViewBuilder
    private var workspaceContent: some View {
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

    private var workspaceStatusTitle: String {
        switch workspace {
        case .adapterComparison:
#if os(macOS)
            adapterStudioViewModel.statusDescription
#else
            String(localized: "Adapter Comparison Requires macOS")
#endif
        case .fmfBench:
            String(localized: "Reference workspace")
        }
    }

    private var workspaceStatusSystemImage: String {
        switch workspace {
        case .adapterComparison:
#if os(macOS)
            switch adapterStudioViewModel.state {
            case .idle:
                adapterStudioViewModel.adapterContext == nil ? "shippingbox" : "circle"
            case .running:
                "circle.dotted"
            case .failed:
                "exclamationmark.triangle"
            case .completed:
                "checkmark.circle"
            }
#else
            "macbook"
#endif
        case .fmfBench:
            "terminal"
        }
    }

    private var workspaceStatusIsActive: Bool {
#if os(macOS)
        workspace == .adapterComparison && adapterStudioViewModel.isRunning
#else
        false
#endif
    }
}

#Preview {
    NavigationStack {
        WorkspaceView(workspace: .fmfBench)
    }
}
