import FMFBenchCore
import XCTest

final class FMFBenchLiveTests: XCTestCase {
    func testPracticalTaskCaptureScenario() async throws {
        let configuration = FMFBenchRunConfiguration(
            suite: .quick,
            scenarios: [FMFBenchScenarioCatalog.taskCapture],
            model: .onDevice,
            warmupCount: 0,
            repetitions: 1
        )

        let result = try await FMFBenchRunner(configuration: configuration).run()

        XCTAssertEqual(result.trials.count, 1)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertGreaterThan(result.trials[0].metrics.duration, 0)
        print(FMFBenchReport(result: result).markdown())
    }
}
