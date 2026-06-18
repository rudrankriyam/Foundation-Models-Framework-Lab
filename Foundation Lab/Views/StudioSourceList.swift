//
//  StudioSourceList.swift
//  Foundation Lab
//

import SwiftUI

struct StudioSourceList: View {
    @Binding var selectedWorkspace: StudioWorkspace
    @Binding var selectedPromptVariants: Set<StudioPromptVariant>

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
            Section("Prompt Variants") {
                ForEach(StudioPromptVariant.allCases) { variant in
                    Toggle(isOn: variantBinding(for: variant)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(variant.title)
                            Text(variant.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
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
        case .structuredOutput, .capabilityMatrix:
            EmptyView()
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

    private func variantBinding(for variant: StudioPromptVariant) -> Binding<Bool> {
        Binding {
            selectedPromptVariants.contains(variant)
        } set: { isSelected in
            if isSelected {
                selectedPromptVariants.insert(variant)
            } else {
                selectedPromptVariants.remove(variant)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedWorkspace = StudioWorkspace.promptTesting
    @Previewable @State var variants = Set(StudioPromptVariant.allCases)

    StudioSourceList(
        selectedWorkspace: $selectedWorkspace,
        selectedPromptVariants: $variants
    )
    .frame(width: 260)
}
