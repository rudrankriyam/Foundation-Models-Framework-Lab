import FMBenchCore
import SwiftUI

struct FMBenchScenarioRow: View {
    let scenario: FMBenchScenario

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(scenario.title)
                    .font(.headline)
                Spacer()

                if scenario.requiresOS27 {
                    Text("OS 27+")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(scenario.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
