import FMFBenchCore
import SwiftUI

struct FMFBenchTuningConfigurationView: View {
    @Bindable var viewModel: FMFBenchViewModel

    var body: some View {
        Picker("Session", selection: $viewModel.selectedSessionMode) {
            ForEach(FMFBenchSessionMode.allCases) { mode in
                Text(mode.displayName).tag(mode)
            }
        }

        Picker("Connectivity", selection: $viewModel.selectedConnectivity) {
            ForEach(FMFBenchConnectivity.allCases) { connectivity in
                Text(connectivity.displayName).tag(connectivity)
            }
        }

        if viewModel.selectedModel == .privateCloudCompute {
            Picker("Reasoning", selection: $viewModel.selectedReasoningLevel) {
                ForEach(FMFBenchReasoningLevel.allCases) { level in
                    Text(level.displayName).tag(level)
                }
            }

            Picker("Fallback", selection: $viewModel.selectedFallbackMode) {
                ForEach(FMFBenchFallbackMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        }

        Stepper(
            "Warmups: \(viewModel.warmupCount)",
            value: $viewModel.warmupCount,
            in: 0...10
        )

        Stepper(
            "Measured runs: \(viewModel.repetitions)",
            value: $viewModel.repetitions,
            in: 1...50
        )

        Toggle("Use all samples", isOn: $viewModel.useAllSamples)

        if !viewModel.useAllSamples {
            Stepper(
                "Samples per workload: \(viewModel.samplesPerScenario)",
                value: $viewModel.samplesPerScenario,
                in: 1...25
            )
        }

        Toggle("Randomize order", isOn: $viewModel.randomizeOrder)
    }
}
