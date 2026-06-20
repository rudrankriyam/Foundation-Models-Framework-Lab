import FMFBenchCore
import SwiftUI

struct FMFBenchResultView: View {
    let result: FMFBenchRunResult
    let copyAction: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Results")
                    .font(.headline)
                Spacer()
                Button("Copy Markdown", systemImage: "doc.on.doc", action: copyAction)
                    .labelStyle(.iconOnly)
                    .accessibilityLabel("Copy Markdown report")
            }

            ForEach(result.summaries) { summary in
                FMFBenchSummaryRow(summary: summary)
            }

            if !result.failures.isEmpty {
                Label(
                    "\(result.failures.count) execution failures are included in the report.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.orange)
            }

            if result.criticalSafetyFailureCount > 0 {
                Label(
                    "\(result.criticalSafetyFailureCount) critical safety failures require review.",
                    systemImage: "shield.slash.fill"
                )
                .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
