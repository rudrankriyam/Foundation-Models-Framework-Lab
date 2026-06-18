//
//  StudioPromptStageView.swift
//  Foundation Lab
//

import SwiftUI

struct StudioPromptStageView: View {
    @Binding var stage: StudioPipelineStage
    @Binding var promptText: String
    @Binding var selectedVariants: Set<StudioPromptVariant>

    let runs: [StudioPromptRun]
    let isRunning: Bool
    let errorMessage: String?

    @State private var selectedRun: StudioPromptRun?

    var body: some View {
        switch stage {
        case .settings:
            StudioPromptSettingsView(
                promptText: $promptText,
                selectedVariants: $selectedVariants,
                isRunning: isRunning,
                errorMessage: errorMessage
            )
        case .runs:
            runsContent
        case .evaluation:
            evaluationContent
        case .preview:
            previewContent
        case .output:
            outputContent
        }
    }

    @ViewBuilder
    private var runsContent: some View {
        if runs.isEmpty, isRunning {
            ContentUnavailableView {
                Label("Running selected variants", systemImage: "hourglass")
            } description: {
                Text("Results will appear here as soon as the first prompt run finishes.")
            } actions: {
                ProgressView()
                    .controlSize(.large)
            }
            .frame(maxWidth: .infinity, minHeight: 320)
        } else if runs.isEmpty {
            unavailableState(
                title: "Prompt runs unavailable",
                systemImage: "play.circle",
                subtitle: "Set up the prompt source and run selected variants to view run progress."
            )
        } else {
            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(runs) { run in
                    runRow(run)
                    Divider()
                }
            }
        }
    }

    private func runRow(_ run: StudioPromptRun) -> some View {
        Button {
            selectedRun = run
        } label: {
            VStack(alignment: .leading, spacing: Spacing.small) {
                HStack(alignment: .firstTextBaseline) {
                    Text(run.variant.title)
                        .font(.headline)

                    Spacer(minLength: Spacing.medium)

                    Text(run.durationLabel)
                        .font(.headline.monospacedDigit())
                }

                Text(run.output)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: Spacing.medium) {
                    Text(run.finishedAt, style: .time)
                    Text(run.tokenLabel)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.vertical, Spacing.small)
        .help("Show full prompt run")
        .popover(
            isPresented: Binding(
                get: { selectedRun?.id == run.id },
                set: { isPresented in
                    if !isPresented, selectedRun?.id == run.id {
                        selectedRun = nil
                    }
                }
            ),
            arrowEdge: .trailing
        ) {
            StudioPromptRunDetailView(run: run)
        }
    }

    @ViewBuilder
    private var evaluationContent: some View {
        if runs.isEmpty {
            unavailableState(
                title: "Evaluation unavailable",
                systemImage: "chart.bar.doc.horizontal",
                subtitle: "Run at least one variant to compare latency, tokens, and answer shape."
            )
        } else {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("Comparison")
                    .font(.headline)

                VStack(spacing: 0) {
                    ForEach(runs) { run in
                        parameterRow(
                            title: run.variant.title,
                            value: "\(run.durationLabel) • \(run.tokenLabel)"
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var previewContent: some View {
        if let latestRun {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                Text(latestRun.variant.title)
                    .font(.headline)
                Text(latestRun.output)
                    .textSelection(.enabled)
            }
        } else {
            unavailableState(
                title: "Preview unavailable",
                systemImage: "eye",
                subtitle: "Run a prompt variant to preview the most recent generated output."
            )
        }
    }

    private var outputContent: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text("Run Artifact")
                .font(.headline)

            VStack(spacing: 0) {
                parameterRow(title: "Format", value: "Studio run summary")
                parameterRow(title: "Runs", value: "\(runs.count)")
                parameterRow(title: "Status", value: runs.isEmpty ? "No exportable runs" : "Ready")
            }

            Button(
                "Review Runs",
                systemImage: "doc.text.magnifyingglass",
                action: showRuns
            )
            .disabled(runs.isEmpty)
        }
    }

    private func parameterRow(title: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(title)
                .font(.callout)
        }
        .padding(.vertical, Spacing.small)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func unavailableState(title: String, systemImage: String, subtitle: String) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(subtitle)
        )
        .frame(maxWidth: .infinity, minHeight: 320)
    }

    private var latestRun: StudioPromptRun? {
        runs.max { $0.finishedAt < $1.finishedAt }
    }

    private func showRuns() {
        stage = .runs
    }
}
