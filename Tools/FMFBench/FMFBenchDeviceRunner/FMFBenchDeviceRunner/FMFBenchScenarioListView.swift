import FMFBenchCore
import SwiftUI

struct FMFBenchScenarioListView: View {
    let scenarios: [FMFBenchScenario]

    var body: some View {
        DisclosureGroup("Workloads (\(scenarios.count))") {
            ForEach(scenarios) { scenario in
                FMFBenchScenarioRow(scenario: scenario)
            }
        }
    }
}
