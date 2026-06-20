import FMBenchCore
import SwiftUI

struct ContentView: View {
    @State private var viewModel = FMBenchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section("Benchmark") {
                    FMBenchConfigurationView(viewModel: viewModel)
                }

                Section {
                    FMBenchScenarioListView(scenarios: viewModel.selectedScenarios)
                }

                if let result = viewModel.result {
                    Section {
                        FMBenchResultView(result: result, copyAction: viewModel.copyMarkdown)
                    }
                }
            }
            .navigationTitle("FMBench")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("FMBench Failed", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}

#Preview {
    ContentView()
}
