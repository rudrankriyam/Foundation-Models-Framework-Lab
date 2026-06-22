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

    #if compiler(>=6.3)
    @available(iOS 27.0, macOS 27.0, *)
    func testPersonalOrganizerPCCScenario() async throws {
        let configuration = FMFBenchRunConfiguration(
            suite: .agentic,
            scenarios: [FMFBenchScenarioCatalog.personalOrganizer],
            model: .privateCloudCompute,
            warmupCount: 0,
            repetitions: 1,
            sampleIDs: ["personal-organizer-001"],
            reasoningLevel: .light,
            fallbackMode: .disabled,
            randomizeOrder: false
        )

        let result = try await FMFBenchRunner(configuration: configuration).run()
        print(FMFBenchReport(result: result).markdown())

        XCTAssertTrue(result.failures.isEmpty)
        let trial = try XCTUnwrap(result.trials.first)
        XCTAssertEqual(result.trials.count, 1)
        XCTAssertEqual(trial.sample.id, "personal-organizer-001")
        XCTAssertEqual(trial.requestedModel, .privateCloudCompute)
        XCTAssertEqual(trial.executedModel, .privateCloudCompute)
        XCTAssertFalse(trial.usedFallback)
        XCTAssertTrue(trial.grade.promptPassed)
    }
    #endif
}
