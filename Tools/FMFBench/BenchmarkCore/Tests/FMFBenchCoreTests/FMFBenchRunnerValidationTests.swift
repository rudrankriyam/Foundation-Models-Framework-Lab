@testable import FMFBenchCore
import Testing

struct FMFBenchRunnerValidationTests {
    @Test
    func runnerRejectsUnknownSampleIDsBeforeExecution() async {
        let scenario = FMFBenchScenarioCatalog.taskCapture
        let runner = FMFBenchRunner(
            configuration: FMFBenchRunConfiguration(
                scenarios: [scenario],
                warmupCount: 0,
                repetitions: 1,
                sampleIDs: [scenario.samples[0].id, "missing-sample"],
                randomizeOrder: false
            )
        )

        do {
            _ = try await runner.run()
            Issue.record("Expected unknown sample IDs to fail before execution.")
        } catch let error as FMFBenchRunner.Error {
            guard case .unknownSampleIDs(let sampleIDs) = error else {
                Issue.record("Expected an unknown sample ID error, got \(error).")
                return
            }
            #expect(sampleIDs == ["missing-sample"])
        } catch {
            Issue.record("Expected an FMFBenchRunner error, got \(error).")
        }
    }

    @Test
    func runnerRejectsConfigurationsWithNoSamples() async {
        let runner = FMFBenchRunner(
            configuration: FMFBenchRunConfiguration(
                scenarios: [],
                warmupCount: 0,
                repetitions: 1,
                randomizeOrder: false
            )
        )

        do {
            _ = try await runner.run()
            Issue.record("Expected an empty configuration to fail before execution.")
        } catch let error as FMFBenchRunner.Error {
            guard case .noSamplesSelected = error else {
                Issue.record("Expected a no samples selected error, got \(error).")
                return
            }
        } catch {
            Issue.record("Expected an FMFBenchRunner error, got \(error).")
        }
    }
}
