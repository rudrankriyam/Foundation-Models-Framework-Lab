import SwiftUI

struct AdapterStudioContent: View {
    let stage: ExpertWorkspaceStage

#if os(macOS)
    let viewModel: AdapterStudioViewModel
#endif

    var body: some View {
#if os(macOS)
        @Bindable var viewModel = viewModel

        Group {
            switch stage {
            case .settings:
                AdapterStudioSettingsView(viewModel: viewModel)
            case .runs:
                AdapterStudioRunsView(viewModel: viewModel)
            case .evaluation:
                AdapterStudioEvaluationView(viewModel: viewModel)
            case .preview:
                AdapterStudioPreviewView(viewModel: viewModel)
            case .output:
                AdapterStudioOutputView(viewModel: viewModel)
            }
        }
        .alert(
            "Adapter Studio",
            isPresented: $viewModel.isShowingError
        ) { } message: {
            Text(viewModel.presentedError)
        }
        .onDisappear(perform: viewModel.cancel)
#else
        ContentUnavailableView(
            "Adapter Comparison Requires macOS",
            systemImage: "macbook",
            description: Text(
                "Use Foundation Lab on a Mac to import .fmadapter packages. "
                    + "Training and export remain available through the fmas CLI."
            )
        )
#endif
    }
}

#Preview {
#if os(macOS)
    AdapterStudioContent(
        stage: .settings,
        viewModel: AdapterStudioViewModel()
    )
    .padding()
#else
    AdapterStudioContent(stage: .settings)
        .padding()
#endif
}
