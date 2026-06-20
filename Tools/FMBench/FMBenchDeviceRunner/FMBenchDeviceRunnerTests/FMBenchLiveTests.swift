import FMBenchCore
import XCTest

final class FMBenchLiveTests: XCTestCase {
    func testPracticalTaskCaptureScenario() async throws {
        let configuration = FMBenchRunConfiguration(
            suite: .quick,
            scenarios: [FMBenchScenarioCatalog.taskCapture],
            model: .onDevice,
            warmupCount: 0,
            repetitions: 1
        )

        let result = try await FMBenchRunner(configuration: configuration).run()

        XCTAssertEqual(result.trials.count, 1)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertGreaterThan(result.trials[0].metrics.duration, 0)
        print(FMBenchReport(result: result).markdown())
    }
}
