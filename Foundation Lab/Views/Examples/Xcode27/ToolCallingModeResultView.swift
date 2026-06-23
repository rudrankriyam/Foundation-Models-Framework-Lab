//
//  ToolCallingModeResultView.swift
//  FoundationLab
//

import SwiftUI

struct ToolCallingModeResultView: View {
    let result: ToolCallingModeRunResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(result.mode.explanation)
                .font(.callout)
                .foregroundStyle(.secondary)

            switch result.state {
            case .pending:
                Label("Not run yet", systemImage: "circle.dashed")
                    .foregroundStyle(.secondary)
            case .running:
                HStack(spacing: Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Waiting for the framework response…")
                }
                .foregroundStyle(.secondary)
            case .cancelled:
                Label("Run stopped before this mode completed.", systemImage: "stop.circle")
                    .foregroundStyle(.secondary)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            case .completed:
                completedContent
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var completedContent: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Xcode27KeyValueList(items: [
                (String(localized: "Transcript calls"), result.transcriptCalls.count.formatted()),
                (String(localized: "Local executions"), result.localToolOutputs.count.formatted()),
                (String(localized: "Elapsed"), durationLabel(result.elapsed))
            ])

            evidenceSection

            if let modelResponse = result.modelResponse {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Model response")
                        .font(.headline)
                    Text(modelResponse)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var evidenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Execution evidence")
                .font(.headline)

            if result.transcriptCalls.isEmpty {
                Label("The transcript contains no tool call.", systemImage: "minus.circle")
                    .foregroundStyle(.secondary)
            } else {
                evidenceList(title: String(localized: "Transcript call"), values: result.transcriptCalls)
                evidenceList(title: String(localized: "Transcript output"), values: result.transcriptOutputs)
                evidenceList(title: String(localized: "Local tool data"), values: result.localToolOutputs)
            }
        }
    }

    private func evidenceList(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .font(.footnote)
                .foregroundStyle(.secondary)

            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.callout.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
    }

    private func durationLabel(_ duration: Duration?) -> String {
        guard let duration else { return String(localized: "Not measured") }
        let components = duration.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }
}
