import FMFBenchCore
import Foundation
import Testing

struct FMFBenchMetricsTests {
    @Test
    func computesNearestRankStatistics() {
        let distribution = FMFBenchDistribution(values: [1, 2, 3, 4, 100])

        #expect(distribution.count == 5)
        #expect(distribution.minimum == 1)
        #expect(distribution.median == 3)
        #expect(distribution.p90 == 100)
        #expect(distribution.maximum == 100)
    }

    @Test
    func throughputUsesOutputTokensAndDecodeTime() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 105)
        let metrics = FMFBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            inputTokenCount: 500,
            outputTokenCount: 101,
            firstStreamUpdateTokenCount: 1,
            tokenCountSource: .systemTokenizer,
            responseCharacterCount: 600,
            streamUpdateDates: [first, end]
        )

        #expect(metrics.decodeDuration == 4)
        #expect(metrics.outputTokensPerSecond == 25)
        #expect(metrics.tokenCountSource == .systemTokenizer)
    }

    @Test
    func throughputExcludesTheEntireFirstStreamUpdate() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 105)
        let metrics = FMFBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            inputTokenCount: 500,
            outputTokenCount: 101,
            firstStreamUpdateTokenCount: 11,
            tokenCountSource: .systemTokenizer,
            responseCharacterCount: 600,
            streamUpdateDates: [first, end]
        )

        #expect(metrics.outputTokensPerSecond == 22.5)
    }

    @Test
    func recordsContextMemoryAndWorstThermalState() {
        let start = Date(timeIntervalSince1970: 100)
        let first = Date(timeIntervalSince1970: 101)
        let end = Date(timeIntervalSince1970: 102)
        let metrics = FMFBenchTrialMetrics(
            startedAt: start,
            endedAt: end,
            firstTokenAt: first,
            inputTokenCount: 500,
            outputTokenCount: 20,
            firstStreamUpdateTokenCount: 2,
            tokenCountSource: .sessionUsage,
            responseCharacterCount: 80,
            streamUpdateDates: [first, end],
            reasoningTokenCount: 12,
            contextSize: 4_000,
            resourceSnapshots: [
                .init(residentMemoryBytes: 100, thermalState: "nominal"),
                .init(residentMemoryBytes: 180, thermalState: "serious"),
                .init(residentMemoryBytes: 150, thermalState: "fair"),
            ]
        )

        #expect(metrics.contextUtilization == 0.125)
        #expect(metrics.peakObservedResidentMemoryBytes == 180)
        #expect(metrics.worstObservedThermalState == "serious")
        #expect(metrics.reasoningTokenCount == 12)
    }

    @Test
    func scenarioSummaryConvertsMemoryBytesNumerically() {
        let start = Date(timeIntervalSince1970: 100)
        let metrics = FMFBenchTrialMetrics(
            startedAt: start,
            endedAt: start.addingTimeInterval(1),
            firstTokenAt: start.addingTimeInterval(0.2),
            inputTokenCount: 10,
            outputTokenCount: 10,
            firstStreamUpdateTokenCount: 1,
            tokenCountSource: .sessionUsage,
            responseCharacterCount: 20,
            streamUpdateDates: [start.addingTimeInterval(0.2), start.addingTimeInterval(1)],
            resourceSnapshots: [
                .init(residentMemoryBytes: 24_477_696, thermalState: "nominal")
            ]
        )
        let environment = EnvironmentSnapshot(
            deviceName: "Test",
            systemName: "macOS",
            systemVersion: "27.0",
            systemBuild: "test",
            localeIdentifier: "en_US",
            hardwareModel: "Test",
            cpuModel: "Test",
            cpuCores: 1,
            gpuModel: "Test",
            totalMemory: 1,
            thermalState: "nominal",
            lowPowerModeEnabled: false,
            fmfBenchCommit: nil
        )
        let scenario = FMFBenchScenarioCatalog.taskCapture
        let trial = FMFBenchTrialResult(
            scenario: scenario,
            sample: scenario.samples[0],
            requestedModel: .onDevice,
            executedModel: .onDevice,
            iteration: 1,
            response: "{}",
            grade: FMFBenchGrader.grade(response: "{}", checks: []),
            metrics: metrics,
            environment: environment
        )
        let result = FMFBenchRunResult(
            suite: .quick,
            model: .onDevice,
            warmupCount: 0,
            repetitions: 1,
            sampleLimit: 1,
            sessionMode: .cold,
            reasoningLevel: .none,
            fallbackMode: .disabled,
            connectivity: .normal,
            randomizedOrder: false,
            randomSeed: 1,
            modelContextSize: 4_096,
            quotaBefore: nil,
            quotaAfter: nil,
            startedAt: start,
            endedAt: start.addingTimeInterval(1),
            environment: environment,
            trials: [trial],
            failures: [
                FMFBenchFailure(
                    scenarioID: scenario.id,
                    sampleID: "failed-sample",
                    iteration: 1,
                    kind: "generation",
                    message: "Test failure",
                    toolCalls: [
                        FMFBenchToolCall(name: "searchContacts", arguments: [:])
                    ],
                    finalState: FMFBenchStateSnapshot(
                        values: ["reminders.count": .integer(0)]
                    )
                )
            ],
            scenarios: [scenario]
        )

        #expect(result.summaries[0].peakObservedResidentMemoryBytes.maximum == 24_477_696)
        #expect(result.summaries[0].promptPassRate == 1)
        #expect(result.summaries[0].failureRate == 0.5)
        #expect(result.summaries[0].endToEndPassRate == 0.5)
        let report = FMFBenchReport(result: result).markdown()
        #expect(report.contains("Task success"))
        #expect(report.contains("Tool sequence: searchContacts"))
        #expect(report.contains("reminders.count=0"))
    }

    @Test
    func safetySummaryTreatsUnexpectedResponsesAsCriticalFailures() {
        let start = Date(timeIntervalSince1970: 100)
        let metrics = FMFBenchTrialMetrics(
            startedAt: start,
            endedAt: start.addingTimeInterval(1),
            firstTokenAt: start.addingTimeInterval(0.2),
            inputTokenCount: 10,
            outputTokenCount: 10,
            firstStreamUpdateTokenCount: 1,
            tokenCountSource: .sessionUsage,
            responseCharacterCount: 20,
            streamUpdateDates: [start.addingTimeInterval(0.2), start.addingTimeInterval(1)]
        )
        let environment = EnvironmentSnapshot(
            deviceName: "Test",
            systemName: "macOS",
            systemVersion: "27.0",
            systemBuild: "test",
            localeIdentifier: "en_US",
            hardwareModel: "Test",
            cpuModel: "Test",
            cpuCores: 1,
            gpuModel: "Test",
            totalMemory: 1,
            thermalState: "nominal",
            lowPowerModeEnabled: false,
            fmfBenchCommit: nil
        )
        let scenario = FMFBenchScenarioCatalog.guardrailExpectedProtection
        let trial = FMFBenchTrialResult(
            scenario: scenario,
            sample: scenario.samples[0],
            requestedModel: .onDevice,
            executedModel: .onDevice,
            iteration: 1,
            safetyOutcome: .responded,
            response: "Unsafe response",
            grade: FMFBenchGrader.grade(response: "Unsafe response", checks: []),
            metrics: metrics,
            environment: environment
        )
        let result = FMFBenchRunResult(
            suite: .guardrails,
            model: .onDevice,
            warmupCount: 0,
            repetitions: 1,
            sampleLimit: 1,
            sessionMode: .cold,
            reasoningLevel: .none,
            fallbackMode: .disabled,
            connectivity: .normal,
            randomizedOrder: false,
            randomSeed: 1,
            modelContextSize: 4_096,
            quotaBefore: nil,
            quotaAfter: nil,
            startedAt: start,
            endedAt: start.addingTimeInterval(1),
            environment: environment,
            trials: [trial],
            failures: [],
            scenarios: [scenario]
        )

        #expect(result.criticalSafetyFailureCount == 1)
        #expect(result.summaries[0].safetyPassRate == 0)
        #expect(result.summaries[0].criticalSafetyFailureCount == 1)
    }
}
