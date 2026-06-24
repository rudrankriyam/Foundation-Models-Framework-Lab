#if os(macOS)
import SwiftUI

struct AdapterStudioRunsView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Prompt")
                    .font(.headline)

                TextField(
                    "Enter one prompt for both models",
                    text: $viewModel.prompt,
                    axis: .vertical
                )
                .lineLimit(5...10)
                .textFieldStyle(.roundedBorder)
                .disabled(viewModel.isRunning)

                HStack {
                    Button(
                        "Clear",
                        systemImage: "eraser",
                        action: viewModel.clearPrompt
                    )
                    .disabled(viewModel.prompt.isEmpty || viewModel.isRunning)

                    Spacer(minLength: 0)

                    if viewModel.isRunning {
                        Button(
                            "Cancel",
                            systemImage: "stop.fill",
                            action: viewModel.cancel
                        )
                    } else {
                        Button(
                            "Run Comparison",
                            systemImage: "play.fill",
                            action: viewModel.submitCurrentPrompt
                        )
                        .buttonStyle(.borderedProminent)
                        .disabled(!viewModel.canRun)
                    }
                }
            }

            if viewModel.adapterContext == nil {
                Label(
                    "Import an adapter in Settings before running a comparison.",
                    systemImage: "info.circle"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if hasComparisonOutput {
                AdapterStudioResponseComparisonView(
                    baseSubtitle: String(localized: "Fresh system model session"),
                    adapterSubtitle: viewModel.adapterContext?.metadata.fileName
                        ?? String(localized: "No adapter loaded"),
                    baseColumn: viewModel.baseColumn,
                    adapterColumn: viewModel.adapterColumn,
                    isActive: viewModel.isRunning
                )
            } else {
                ContentUnavailableView(
                    "Ready to Compare",
                    systemImage: "square.split.2x1",
                    description: Text("Enter one prompt to inspect the base model and custom adapter side by side.")
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            }
        }
    }

    private var hasComparisonOutput: Bool {
        viewModel.isRunning
            || viewModel.lastResult != nil
            || !viewModel.baseColumn.text.isEmpty
            || !viewModel.adapterColumn.text.isEmpty
            || viewModel.baseColumn.errorMessage != nil
            || viewModel.adapterColumn.errorMessage != nil
    }
}
#endif
