//
//  AppBenchStudioContent.swift
//  Foundation Lab
//
//  Created by Codex on 6/12/26.
//

import SwiftUI

struct AppBenchStudioContent: View {
    let stage: StudioPipelineStage

    var body: some View {
        switch stage {
        case .settings:
            settingsContent
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

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            section(title: "Execution Surfaces") {
                VStack(spacing: 0) {
                    detailRow(title: "Mac", value: "appbench CLI")
                    Divider()
                    detailRow(title: "iPhone and iPad", value: "Signed AppBenchDeviceRunner")
                    Divider()
                    detailRow(title: "Simulator", value: "Build and interface validation only")
                }
            }

            section(title: "Publishable Protocol") {
                VStack(spacing: 0) {
                    detailRow(title: "Warmups", value: "5")
                    Divider()
                    detailRow(title: "Measured runs", value: "20 or more")
                    Divider()
                    detailRow(title: "Order", value: "Randomized with a recorded seed")
                    Divider()
                    detailRow(title: "Report", value: "Median, p90, and failure rate")
                }
            }
        }
    }

    private var runsContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            section(title: "Mac CLI") {
                command("swift run appbench --suite quick --model on-device")
            }

            section(title: "Physical Device") {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text("Open the AppBenchDeviceRunner project, select a physical Apple Intelligence device, and run its scheme.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                    command("Tools/AppBench/AppBenchDeviceRunner/AppBenchDeviceRunner.xcodeproj")
                }
            }
        }
    }

    private var evaluationContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            section(title: "Quality") {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    note(
                        title: "Deterministic graders",
                        detail: "Exact fields, constraints, citations, tool calls, and grounded claims."
                    )
                    note(
                        title: "Guided generation",
                        detail: "Grades semantic values only; token-time schema validity is not counted as quality."
                    )
                }
            }

            section(title: "Performance") {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    note(title: "Latency", detail: "TTFT, decode duration, and end-to-end duration.")
                    note(title: "Throughput", detail: "Output tokens per second after the first streamed update.")
                    note(title: "Runtime", detail: "Memory, thermal state, context use, failures, and PCC quota state.")
                }
            }
        }
    }

    private var previewContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            section(title: "Suites") {
                VStack(spacing: 0) {
                    detailRow(title: "Practical Quick", value: "Fast development pass")
                    Divider()
                    detailRow(title: "Practical Full", value: "10 workloads, 25 samples each")
                    Divider()
                    detailRow(title: "Safety Guardrails", value: "False positives and expected protection")
                    Divider()
                    detailRow(title: "Synthetic Performance", value: "Sustained generation")
                    Divider()
                    detailRow(title: "Context Limits", value: "Long-context behavior")
                }
            }

            Text(
                "Workloads cover task parsing, workout generation, summarization, classification, grounded explanation, "
                    + "exercise substitution, document Q&A, citation extraction, creative writing, and visual recommendation."
            )
            .font(.callout)
            .foregroundStyle(.secondary)
        }
    }

    private var outputContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            section(title: "Artifacts") {
                VStack(spacing: 0) {
                    detailRow(title: "JSON", value: "Complete machine-readable trials and environment")
                    Divider()
                    detailRow(title: "Markdown", value: "Human-readable scenario summaries")
                    Divider()
                    detailRow(title: "Curated results", value: "Tools/AppBench/Results")
                }
            }

            command(
                "swift run appbench --suite full "
                    + "--json Tools/AppBench/Results/run.json "
                    + "--markdown Tools/AppBench/Results/run.md"
            )
        }
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(title)
                .font(.headline)

            content()
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(title)
        }
        .padding(.vertical, Spacing.small)
    }

    private func command(_ command: String) -> some View {
        Text(command)
            .font(.system(.callout, design: .monospaced))
            .textSelection(.enabled)
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.small))
    }

    private func note(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ScrollView {
        AppBenchStudioContent(stage: .settings)
            .padding()
    }
}
