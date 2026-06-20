#if os(macOS)
import SwiftUI

struct AdapterStudioOutputView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Latest Output")
                    .font(.headline)

                Text("Responses remain selectable for manual review. Use AppBench when you need stored datasets and deterministic graders.")
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
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: Spacing.large) {
                        AdapterStudioResponseColumn(
                            title: String(localized: "Base Model"),
                            subtitle: String(localized: "System language model"),
                            column: viewModel.baseColumn,
                            isActive: false
                        )

                        Divider()

                        AdapterStudioResponseColumn(
                            title: String(localized: "Custom Adapter"),
                            subtitle: viewModel.adapterContext?.metadata.fileName
                                ?? String(localized: "Adapter"),
                            column: viewModel.adapterColumn,
                            isActive: false
                        )
                    }

                    VStack(spacing: Spacing.large) {
                        AdapterStudioResponseColumn(
                            title: String(localized: "Base Model"),
                            subtitle: String(localized: "System language model"),
                            column: viewModel.baseColumn,
                            isActive: false
                        )

                        Divider()

                        AdapterStudioResponseColumn(
                            title: String(localized: "Custom Adapter"),
                            subtitle: viewModel.adapterContext?.metadata.fileName
                                ?? String(localized: "Adapter"),
                            column: viewModel.adapterColumn,
                            isActive: false
                        )
                    }
                }
            }
        }
    }
}
#endif
