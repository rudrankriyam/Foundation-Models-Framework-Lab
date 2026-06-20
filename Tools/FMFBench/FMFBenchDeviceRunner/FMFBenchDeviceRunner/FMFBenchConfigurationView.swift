import FMFBenchCore
import SwiftUI

struct FMFBenchConfigurationView: View {
    @Bindable var viewModel: FMFBenchViewModel

    var body: some View {
        Picker("Suite", selection: $viewModel.selectedSuite) {
            ForEach(FMFBenchSuite.allCases) { suite in
                Text(suite.displayName).tag(suite)
            }
        }

        Picker("Model", selection: $viewModel.selectedModel) {
            ForEach(FMFBenchModel.allCases) { model in
                Text(model.displayName).tag(model)
            }
        }

        LabeledContent("Protocol") {
            Text("\(viewModel.warmupCount) warmups / \(viewModel.repetitions) runs")
                .foregroundStyle(.secondary)
        }

        #if targetEnvironment(simulator)
        VStack(alignment: .leading) {
            Label("Physical device required", systemImage: "iphone.slash")
            Text("Simulator is for interface validation only.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        #else
        Button(
            viewModel.isRunning ? "Running..." : "Run Benchmark",
            systemImage: viewModel.isRunning ? "hourglass" : "play.fill",
            action: viewModel.run
        )
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .frame(maxWidth: .infinity)
        .disabled(viewModel.isRunning)
        .accessibilityHint("Runs the selected Foundation Models benchmark configuration")
        #endif

        DisclosureGroup("Advanced") {
            FMFBenchAdvancedConfigurationView(viewModel: viewModel)
        }

        if viewModel.isRunning {
            HStack {
                ProgressView()
                Text("Benchmark in progress")
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}
