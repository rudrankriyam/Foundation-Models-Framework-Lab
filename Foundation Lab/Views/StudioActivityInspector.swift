//
//  StudioActivityInspector.swift
//  Foundation Lab
//

import SwiftUI

struct StudioActivityInspector: View {
    let workspace: StudioWorkspace
    let promptRuns: [StudioPromptRun]
    let selectedVariantCount: Int
    let createdAt: Date

    var body: some View {
        switch workspace {
        case .adapterComparison:
            AdapterStudioInspector()
        case .benchmarkRuns:
            AppBenchStudioInspector()
        case .promptTesting:
            promptInspector
        }
    }

    private var promptInspector: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            summary
            Divider()

            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack {
                    Text("Activity")
                        .font(.headline)
                    Spacer()
                    Text(Date.now, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(activityEvents) { event in
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(event.title)
                                .font(.callout)
                            Spacer()
                            Text(event.date, style: .time)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }

                        Text(event.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Spacing.small)

                    Divider()
                }
            }
        }
        .padding(Spacing.large)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            metric(value: "\(promptRuns.count)", title: "Runs")
            metric(value: averageDurationLabel, title: "Average")
            metric(value: "\(selectedVariantCount)", title: "Variants")
        }
    }

    private func metric(value: String, title: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.callout.monospacedDigit())
                .lineLimit(1)
        } label: {
            Text(title)
                .font(.callout)
        }
    }

    private var averageDurationLabel: String {
        guard !promptRuns.isEmpty else { return "--" }
        let totalDuration = promptRuns.reduce(0) { $0 + $1.duration }
        let average = totalDuration / Double(promptRuns.count)
        return "\(average.formatted(.number.precision(.fractionLength(2))))s"
    }

    private var activityEvents: [StudioActivityEvent] {
        if promptRuns.isEmpty {
            return [
                StudioActivityEvent(
                    id: "studio-created",
                    title: "Studio Created",
                    detail: "Local Evaluation Studio",
                    date: createdAt
                )
            ]
        }

        return promptRuns.prefix(6).map {
            StudioActivityEvent(
                id: $0.id.uuidString,
                title: "Prompt Variant Completed",
                detail: $0.variant.title,
                date: $0.finishedAt
            )
        }
    }
}
