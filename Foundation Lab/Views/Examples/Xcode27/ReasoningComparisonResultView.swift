//
//  ReasoningComparisonResultView.swift
//  FoundationLab
//

import SwiftUI

struct ReasoningComparisonResultView: View {
    let result: ReasoningComparisonResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.large) {
            Text(result.level.requestedBudgetDescription)
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
                Label("Run stopped before this response completed.", systemImage: "stop.circle")
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
                (String(localized: "Elapsed"), durationLabel(result.elapsed)),
                (String(localized: "Input"), tokenLabel(result.inputTokens)),
                (String(localized: "Cached input"), tokenLabel(result.cachedInputTokens)),
                (String(localized: "Output"), tokenLabel(result.outputTokens)),
                (String(localized: "Reasoning output"), tokenLabel(result.reasoningTokens)),
                (String(localized: "Total"), tokenLabel(result.totalTokens))
            ])

            if let response = result.response {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Model response")
                        .font(.headline)
                    Text(response)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private func tokenLabel(_ count: Int?) -> String {
        guard let count else { return String(localized: "Not reported") }
        return count == 1 ? String(localized: "1 token") : String(localized: "\(count) tokens")
    }

    private func durationLabel(_ duration: Duration?) -> String {
        guard let duration else { return String(localized: "Not measured") }
        let components = duration.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }
}
