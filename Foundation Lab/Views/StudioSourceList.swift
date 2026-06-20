//
//  StudioSourceList.swift
//  Foundation Lab
//

import SwiftUI

struct StudioSourceList: View {
    @Binding var selectedWorkspace: StudioWorkspace

    var body: some View {
        List {
            Section("Workspaces") {
                Picker("Workspace", selection: $selectedWorkspace) {
                    ForEach(StudioWorkspace.allCases) { workspace in
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(workspace.title)
                                Text(workspace.status)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: workspace.icon)
                        }
                        .tag(workspace)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }

            workspaceSources
        }
        .listStyle(.sidebar)
    }

    @ViewBuilder
    private var workspaceSources: some View {
        switch selectedWorkspace {
        case .promptTesting:
            EmptyView()
        case .benchmarkRuns:
            Section("Runners") {
                sourceInfoRow(title: "Mac CLI", subtitle: "Publishable", systemImage: "terminal")
                sourceInfoRow(title: "Device Runner", subtitle: "iPhone and iPad", systemImage: "iphone")
                sourceInfoRow(title: "Simulator", subtitle: "Validation only", systemImage: "hammer")
            }
        case .adapterComparison:
            Section("Surfaces") {
                sourceInfoRow(title: "Base Model", subtitle: "Fresh session", systemImage: "cpu")
                sourceInfoRow(title: "Custom Adapter", subtitle: ".fmadapter", systemImage: "shippingbox")
                sourceInfoRow(title: "Training CLI", subtitle: "fmas", systemImage: "terminal")
            }
        }
    }

    private func sourceInfoRow(title: String, subtitle: String, systemImage: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
        }
    }

}

#Preview {
    @Previewable @State var selectedWorkspace = StudioWorkspace.promptTesting

    StudioSourceList(selectedWorkspace: $selectedWorkspace)
    .frame(width: 260)
}
