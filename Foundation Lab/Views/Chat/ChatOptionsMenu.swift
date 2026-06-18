//
//  ChatOptionsMenu.swift
//  FoundationLab
//
import FoundationLabCore
import SwiftUI

struct ChatOptionsMenu: View {
    @Bindable var viewModel: ChatViewModel

    let isChatEmpty: Bool
    let onSelectModelRuntime: (FoundationLabModelRuntime) -> Void
    let onSelectReasoningLevel: (FoundationLabReasoningLevel) -> Void
    let onShowInstructions: () -> Void
    let onClearChat: () -> Void

    var body: some View {
        Menu {
            Section("Mode") {
                ForEach(FoundationLabModelRuntime.allCases, id: \.self) { runtime in
                    Button {
                        onSelectModelRuntime(runtime)
                    } label: {
                        Label {
                            Text(runtime.displayName)
                        } icon: {
                            Image(systemName: modelRuntimeIcon(for: runtime))
                        }
                    }
                    .disabled(runtime == .privateCloudCompute && !viewModel.canSelectPrivateCloudCompute)
                    .accessibilityValue(runtime == viewModel.selectedModelRuntime ? "Selected" : "")
                }

                Text(viewModel.modelRuntimeStatus)
            }

            Section("Generation Options") {
                ForEach(FoundationLabReasoningLevel.allCases, id: \.self) { level in
                    Button {
                        onSelectReasoningLevel(level)
                    } label: {
                        Label {
                            Text(level.displayName)
                        } icon: {
                            Image(systemName: reasoningLevelIcon(for: level))
                        }
                    }
                    .disabled(level != .none && !viewModel.canUseReasoning)
                    .accessibilityValue(level == viewModel.selectedReasoningLevel ? "Selected" : "")
                }

                Toggle("Show Reasoning Trace", systemImage: "text.alignleft", isOn: $viewModel.showsReasoningTrace)
                    .disabled(viewModel.selectedModelRuntime == .onDevice)

                if !viewModel.canUseReasoning {
                    Text("Reasoning levels require PCC on Xcode 27.")
                }
            }

            Section {
                Button("Instructions", systemImage: "doc.text", action: onShowInstructions)

                Button(role: .destructive, action: onClearChat) {
                    Label("Clear chat", systemImage: "trash")
                }
                .disabled(isChatEmpty)
            }
        } label: {
            Label("More Options", systemImage: "slider.horizontal.3")
        }
        .help("More Options")
        .accessibilityLabel("More Options")
    }

    private func modelRuntimeIcon(for runtime: FoundationLabModelRuntime) -> String {
        runtime == viewModel.selectedModelRuntime ? "checkmark" : runtime.systemImage
    }

    private func reasoningLevelIcon(for level: FoundationLabReasoningLevel) -> String {
        level == viewModel.selectedReasoningLevel ? "checkmark" : level.systemImage
    }
}
