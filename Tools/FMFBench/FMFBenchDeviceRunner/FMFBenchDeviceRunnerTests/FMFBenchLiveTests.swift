import FMFBenchCore
import Foundation
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

    @available(iOS 27.0, macOS 27.0, *)
    func testAppsPCCSuiteWhenRequested() async throws {
        guard ProcessInfo.processInfo.environment["FMFBENCH_LIVE_APPS_PCC"] == "1" else {
            throw XCTSkip("Set FMFBENCH_LIVE_APPS_PCC=1 to run the live PCC apps suite.")
        }

        let configuration = FMFBenchRunConfiguration(
            suite: .apps,
            model: .privateCloudCompute,
            warmupCount: 0,
            repetitions: 1,
            useAllSamples: true,
            fallbackMode: .disabled,
            randomizeOrder: false
        )

        let result = try await FMFBenchRunner(configuration: configuration).run()
        let report = FMFBenchReport(result: result)
        let outputDirectory = URL(
            fileURLWithPath: ProcessInfo.processInfo.environment["FMFBENCH_LIVE_OUTPUT_DIR"]
                ?? "/tmp/fmfbench-apps-pcc"
        )
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let jsonURL = outputDirectory.appending(path: "apps-pcc.json")
        let markdownURL = outputDirectory.appending(path: "apps-pcc.md")
        try report.json().write(to: jsonURL, atomically: true, encoding: .utf8)
        try report.markdown().write(to: markdownURL, atomically: true, encoding: .utf8)

        print(report.markdown())
        print("FMFBench PCC JSON: \(jsonURL.path())")
        print("FMFBench PCC Markdown: \(markdownURL.path())")

        XCTAssertEqual(result.trials.count, 10)
        XCTAssertTrue(result.failures.isEmpty)
        XCTAssertTrue(result.trials.allSatisfy { $0.requestedModel == .privateCloudCompute })
        XCTAssertTrue(result.trials.allSatisfy { $0.executedModel == .privateCloudCompute })
    }
    #endif
}
