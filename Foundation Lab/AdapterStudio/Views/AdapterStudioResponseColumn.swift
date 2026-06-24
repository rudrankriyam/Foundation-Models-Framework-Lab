#if os(macOS)
import SwiftUI

struct AdapterStudioResponseColumn: View {
    let title: String
    let subtitle: String
    let column: AdapterStudioColumnState
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Divider()

            ScrollView {
                if let errorMessage = column.errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                        .font(.callout)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("Error: \(errorMessage)")
                } else if column.text.isEmpty {
                    HStack(spacing: Spacing.small) {
                        if isActive {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(
                            isActive
                                ? String(localized: "Waiting for the first token")
                                : String(localized: "No response yet")
                        )
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(column.text)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(minHeight: 220)

            if let metrics = column.metrics {
                Divider()

                HStack(spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("First token")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(durationLabel(metrics.timeToFirstToken))
                            .font(.callout.monospacedDigit())
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Total")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(durationLabel(metrics.totalDuration))
                            .font(.callout.monospacedDigit())
                    }

                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(minWidth: 280, maxWidth: .infinity, alignment: .topLeading)
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
}

#Preview {
    AdapterStudioResponseColumn(
        title: String(localized: "Base Model"),
        subtitle: String(localized: "System language model"),
        column: AdapterStudioColumnState(text: "Example response"),
        isActive: false
    )
    .frame(width: 440)
    .padding()
}
#endif
