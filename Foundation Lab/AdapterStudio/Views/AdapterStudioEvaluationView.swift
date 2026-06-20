#if os(macOS)
import SwiftUI

struct AdapterStudioEvaluationView: View {
    @Bindable var viewModel: AdapterStudioViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Interactive Timing")
                    .font(.headline)

                Text("""
                The two models stream concurrently for fast visual comparison. Treat these timings as diagnostics; \
                use FMBench for controlled, publishable measurements.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if viewModel.baseColumn.metrics == nil
                && viewModel.adapterColumn.metrics == nil {
                ContentUnavailableView(
                    "No Comparison Yet",
                    systemImage: "chart.bar",
                    description: Text(
                        "Run the same prompt through the base model and adapter first."
                    )
                )
                .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                Grid(
                    alignment: .leading,
                    horizontalSpacing: Spacing.xLarge,
                    verticalSpacing: Spacing.medium
                ) {
                    GridRow {
                        Text("Metric")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text("Base")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text("Adapter")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                        Text("Adapter delta")
                            .font(.subheadline.bold())
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .gridCellColumns(4)

                    GridRow {
                        Text("Time to first token")
                        Text(
                            durationLabel(
                                viewModel.baseColumn.metrics?.timeToFirstToken
                            )
                        )
                        Text(
                            durationLabel(
                                viewModel.adapterColumn.metrics?.timeToFirstToken
                            )
                        )
                        Text(
                            deltaLabel(
                                base: viewModel.baseColumn.metrics?.timeToFirstToken,
                                adapter: viewModel.adapterColumn.metrics?.timeToFirstToken
                            )
                        )
                    }

                    GridRow {
                        Text("Total duration")
                        Text(
                            durationLabel(
                                viewModel.baseColumn.metrics?.totalDuration
                            )
                        )
                        Text(
                            durationLabel(
                                viewModel.adapterColumn.metrics?.totalDuration
                            )
                        )
                        Text(
                            deltaLabel(
                                base: viewModel.baseColumn.metrics?.totalDuration,
                                adapter: viewModel.adapterColumn.metrics?.totalDuration
                            )
                        )
                    }
                }
                .font(.callout.monospacedDigit())
            }
        }
    }

    private func durationLabel(_ duration: TimeInterval?) -> String {
        guard let duration else { return "--" }
        return Measurement(value: duration, unit: UnitDuration.seconds).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(2))
            )
        )
    }

    private func deltaLabel(
        base: TimeInterval?,
        adapter: TimeInterval?
    ) -> String {
        guard let base, let adapter else { return "--" }
        let delta = adapter - base
        return Measurement(value: delta, unit: UnitDuration.seconds).formatted(
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number
                    .sign(strategy: .always(includingZero: false))
                    .precision(.fractionLength(2))
            )
        )
    }
}
#endif
