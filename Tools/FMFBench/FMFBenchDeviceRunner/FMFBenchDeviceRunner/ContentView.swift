import FMFBenchCore
import SwiftUI

struct ContentView: View {
    @State private var viewModel = FMFBenchViewModel()

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            List {
                Section("Benchmark") {
                    FMFBenchConfigurationView(viewModel: viewModel)
                }

                Section {
                    FMFBenchScenarioListView(scenarios: viewModel.selectedScenarios)
                }

                if let result = viewModel.result {
                    Section {
                        FMFBenchResultView(result: result, copyAction: viewModel.copyMarkdown)
                    }
                }
            }
            .navigationTitle("FMFBench")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .alert("FMFBench Failed", isPresented: $viewModel.showError) {
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
