import FMBenchCore
import SwiftUI

struct FMBenchSummaryRow: View {
    let summary: FMBenchScenarioSummary

    var body: some View {
        DisclosureGroup {
            LabeledContent("Constraint score") {
                Text(summary.meanConstraintScore, format: .percent.precision(.fractionLength(1)))
            }

            LabeledContent("Failure rate") {
                Text(summary.failureRate, format: .percent.precision(.fractionLength(1)))
            }

            if let safetyPassRate = summary.safetyPassRate {
                LabeledContent("Safety pass") {
                    Text(safetyPassRate, format: .percent.precision(.fractionLength(1)))
                }

                LabeledContent("Guardrail / refusal") {
                    Text("\(summary.guardrailViolationCount) / \(summary.refusalCount)")
                }
            }

            LabeledContent("Median TTFT", value: metric(summary.timeToFirstToken.median, suffix: "s", precision: 3))
            LabeledContent(
                "Median output speed",
                value: metric(summary.outputTokensPerSecond.median, suffix: " tok/s", precision: 2)
            )
        } label: {
            HStack {
                Text(summary.title)
                    .font(.headline)
                Spacer()
                Text(summary.promptPassRate, format: .percent.precision(.fractionLength(0)))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func metric(_ value: Double?, suffix: String, precision: Int) -> String {
        guard let value else { return "n/a" }
        let formatted = value.formatted(.number.precision(.fractionLength(precision)))
        return "\(formatted)\(suffix)"
    }
}
