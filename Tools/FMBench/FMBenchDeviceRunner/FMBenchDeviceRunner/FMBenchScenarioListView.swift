import FMBenchCore
import SwiftUI

struct FMBenchScenarioListView: View {
    let scenarios: [FMBenchScenario]

    var body: some View {
        DisclosureGroup("Workloads (\(scenarios.count))") {
            ForEach(scenarios) { scenario in
                FMBenchScenarioRow(scenario: scenario)
            }
        }
    }
}
