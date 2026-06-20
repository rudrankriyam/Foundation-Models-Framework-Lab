import FoundationLabCore
import SwiftUI

struct PlaygroundHeaderView: View {
    let configuration: FoundationLabExperimentConfiguration
    let toolCount: Int
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.medium) {
                title
                Spacer(minLength: Spacing.large)
                metadata
            }

            VStack(alignment: .leading, spacing: Spacing.small) {
                title
                metadata
            }
        }
        .padding(.horizontal, Spacing.large)
        .padding(.vertical, Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.bar)
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(configuration.name.isEmpty ? "Untitled Experiment" : configuration.name)
                .font(.headline)

            if !configuration.summary.isEmpty {
                Text(configuration.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 2)
            }
        }
    }

    private var metadata: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.medium) {
                experimentTypeLabel
                runtimeLabel

                if toolCount > 0 {
                    toolCountLabel
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                HStack(spacing: Spacing.medium) {
                    experimentTypeLabel
                    runtimeLabel
                }

                if toolCount > 0 {
                    toolCountLabel
                }
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private var experimentTypeLabel: some View {
        Label(configuration.kind.displayName, systemImage: configuration.kind.systemImage)
    }

    private var runtimeLabel: some View {
        Label(configuration.modelRuntime.shortName, systemImage: configuration.modelRuntime.systemImage)
    }

    private var toolCountLabel: some View {
        Label {
            Text("^[\(toolCount) tool](inflect: true)")
        } icon: {
            Image(systemName: "wrench.and.screwdriver")
        }
    }
}
