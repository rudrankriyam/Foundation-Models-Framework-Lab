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

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.large) {
                    AdapterStudioResponseColumn(
                        title: String(localized: "Base Model"),
                        subtitle: String(localized: "Fresh system model session"),
                        column: viewModel.baseColumn,
                        isActive: viewModel.isRunning
                    )

                    Divider()

                    AdapterStudioResponseColumn(
                        title: String(localized: "Custom Adapter"),
                        subtitle: viewModel.adapterContext?.metadata.fileName
                            ?? String(localized: "No adapter loaded"),
                        column: viewModel.adapterColumn,
                        isActive: viewModel.isRunning
                    )
                }

                VStack(spacing: Spacing.large) {
                    AdapterStudioResponseColumn(
                        title: String(localized: "Base Model"),
                        subtitle: String(localized: "Fresh system model session"),
                        column: viewModel.baseColumn,
                        isActive: viewModel.isRunning
                    )

                    Divider()

                    AdapterStudioResponseColumn(
                        title: String(localized: "Custom Adapter"),
                        subtitle: viewModel.adapterContext?.metadata.fileName
                            ?? String(localized: "No adapter loaded"),
                        column: viewModel.adapterColumn,
                        isActive: viewModel.isRunning
                    )
                }
            }
        }
    }
}
#endif
