#if os(macOS)
import SwiftUI

struct AdapterStudioOutputView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Latest Output")
                    .font(.headline)

                Text("Responses remain selectable for manual review. Use FMFBench when you need stored datasets and deterministic graders.")
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if viewModel.lastResult == nil {
                ContentUnavailableView(
                    "No Completed Comparison",
                    systemImage: "doc.text",
                    description: Text("Run a comparison to populate this output.")
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                AdapterStudioResponseComparisonView(
                    baseSubtitle: String(localized: "System language model"),
                    adapterSubtitle: viewModel.adapterContext?.metadata.fileName
                        ?? String(localized: "Adapter"),
                    baseColumn: viewModel.baseColumn,
                    adapterColumn: viewModel.adapterColumn,
                    isActive: false
                )
            }
        }
    }
}
#endif
