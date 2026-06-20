@testable import FMFBenchDeviceRunner
import FMFBenchCore
import XCTest

@MainActor
final class FMFBenchViewModelTests: XCTestCase {
    func testSuiteChangesApplySuiteSampleDefaults() {
        let viewModel = FMFBenchViewModel()

        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)

        viewModel.selectedSuite = .full
        XCTAssertTrue(viewModel.useAllSamples)
        XCTAssertNil(viewModel.makeConfiguration().sampleLimit)

        viewModel.useAllSamples = false
        viewModel.samplesPerScenario = 3
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 3)

        viewModel.selectedSuite = .quick
        XCTAssertFalse(viewModel.useAllSamples)
        XCTAssertEqual(viewModel.makeConfiguration().sampleLimit, 1)
    }
}
