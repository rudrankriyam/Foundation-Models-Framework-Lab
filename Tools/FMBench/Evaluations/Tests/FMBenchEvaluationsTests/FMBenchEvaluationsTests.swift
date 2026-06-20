import FMBenchCore
import FMBenchEvaluations
import Evaluations
import Foundation
import XCTest

@available(macOS 27.0, *)
final class FMBenchEvaluationsTests: XCTestCase {
  func testConvertsScenarioCorpusToEvaluationSamples() throws {
    let samples = try FMBenchEvaluationsAdapter.samples(
      for: FMBenchScenarioCatalog.taskCapture
    )

    XCTAssertEqual(samples.count, 25)
    XCTAssertEqual(samples[0].recordID, "task-capture-001")
    XCTAssertNil(samples[0].expected)
    XCTAssertNotNil(samples[0].generationSchema)
  }

  func testCreatesToolCallEvaluatorForToolWorkloadsOnly() {
    XCTAssertNotNil(
      FMBenchEvaluationsAdapter.toolCallEvaluator(
        for: FMBenchScenarioCatalog.groundedExplanation
      )
    )
    XCTAssertNil(
      FMBenchEvaluationsAdapter.toolCallEvaluator(
        for: FMBenchScenarioCatalog.journalSummary
      )
    )
  }

  func testAgenticScenarioPreservesOrderedTrajectoryExpectations() throws {
    let samples = try FMBenchEvaluationsAdapter.samples(
      for: FMBenchScenarioCatalog.personalOrganizer
    )
    let expectation = try XCTUnwrap(samples[0].output.expectations)

    XCTAssertEqual(
      expectation.ordered.map(\.name),
      ["searchContacts", "listReminders", "createReminder"]
    )
    XCTAssertFalse(expectation.allowsAdditionalCalls)

    let missingContactExpectation = try XCTUnwrap(samples[10].output.expectations)
    XCTAssertEqual(missingContactExpectation.ordered.map(\.name), ["searchContacts"])
    XCTAssertEqual(
      Set(missingContactExpectation.disallowed.map(\.name)),
      Set(["createReminder"])
    )
  }

  func testLoadsCurrentFMBenchResult() throws {
    let run = makeCurrentRun()
    let data = try XCTUnwrap(
      FMBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMBenchRecordedRunLoader.decode(
      data,
      sourceName: "current.json"
    )

    XCTAssertEqual(recorded.records.count, 1)
    XCTAssertEqual(recorded.records[0].sampleID, run.trials[0].sample.id)
    XCTAssertEqual(recorded.info["FMBench Source Schema"], "current")
    XCTAssertEqual(recorded.info["FMBench Source File"], "current.json")
  }

  func testCurrentResultExcludesWarmupFailures() throws {
    let run = makeCurrentRun(
      failures: [
        FMBenchFailure(
          scenarioID: "__warmup__",
          sampleID: "__warmup__-1",
          iteration: 1,
          kind: "availability",
          message: "Warmup failed"
        ),
        FMBenchFailure(
          scenarioID: FMBenchScenarioCatalog.journalSummary.id,
          sampleID: FMBenchScenarioCatalog.journalSummary.samples[0].id,
          iteration: 2,
          kind: "generation",
          message: "Measured trial failed"
        )
      ]
    )
    let data = try XCTUnwrap(
      FMBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMBenchRecordedRunLoader.decode(data)

    XCTAssertEqual(recorded.records.count, 2)
    XCTAssertFalse(recorded.records.contains { $0.scenarioID == "__warmup__" })
    XCTAssertEqual(
      recorded.records.count(where: { !$0.executionSucceeded }),
      1
    )
  }

  func testCurrentSafetyFailurePreservesRecordedOutcome() throws {
    let scenario = FMBenchScenarioCatalog.guardrailExpectedProtection
    let sample = scenario.samples[0]
    let run = makeCurrentRun(
      scenario: scenario,
      failures: [
        FMBenchFailure(
          scenarioID: scenario.id,
          sampleID: sample.id,
          iteration: 2,
          kind: "guardrail",
          message: "Generation was blocked"
        )
      ]
    )
    let data = try XCTUnwrap(
      FMBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMBenchRecordedRunLoader.decode(data)
    let failure = try XCTUnwrap(
      recorded.records.first { !$0.executionSucceeded }
    )

    XCTAssertEqual(failure.safetyExpectation, .mustProtect)
    XCTAssertEqual(failure.safetyOutcome, .guardrailViolation)
  }

  func testLoadsLegacyFMBenchResult() throws {
    let json = """
      {
        "suite": "quick",
        "model": "onDevice",
        "warmupCount": 1,
        "repetitions": 2,
        "startedAt": "2026-06-12T08:37:34Z",
        "endedAt": "2026-06-12T08:37:35Z",
        "environment": {
          "deviceName": "MacBook Pro",
          "systemName": "macOS",
          "systemVersion": "27.0",
          "systemBuild": "26A5353q",
          "hardwareModel": "Mac17,2",
          "cpuModel": "Apple M5",
          "fmBenchCommit": "abc123"
        },
        "trials": [{
          "id": "DE0A593A-DEB4-415B-A9FC-1D016364E070",
          "scenario": {
            "id": "journal-summary",
            "title": "Historical journal summary",
            "instructions": "Answer briefly.",
            "prompt": "Historical prompt",
            "checks": []
          },
          "model": "onDevice",
          "iteration": 1,
          "response": "Hello",
          "metrics": {
            "duration": 1.25,
            "timeToFirstToken": 0.2,
            "outputTokensPerSecond": 30
          }
        }],
        "failures": [
          {
            "id": "73D234B8-C266-4ECF-8A28-ECC2DF3657DC",
            "scenarioID": "__warmup__",
            "iteration": 1,
            "message": "Warmup failed"
          },
          {
            "id": "90788F0C-28B3-44A8-97A2-E3C98494AB72",
            "scenarioID": "journal-summary",
            "iteration": 2,
            "message": "Measured trial failed"
          }
        ]
      }
      """

    let recorded = try FMBenchRecordedRunLoader.decode(
      Data(json.utf8),
      sourceName: "legacy.json"
    )

    XCTAssertEqual(recorded.records.count, 2)
    XCTAssertEqual(recorded.records[0].scenarioID, "journal-summary")
    XCTAssertEqual(recorded.records[0].duration, 1.25)
    XCTAssertFalse(recorded.records.contains { $0.scenarioID == "__warmup__" })
    XCTAssertEqual(
      recorded.records.count(where: { !$0.executionSucceeded }),
      1
    )
    let failure = try XCTUnwrap(
      recorded.records.first { !$0.executionSucceeded }
    )
    XCTAssertEqual(failure.scenarioTitle, "Historical journal summary")
    XCTAssertEqual(failure.prompt, "Historical prompt")
    XCTAssertTrue(failure.checks.isEmpty)
    XCTAssertEqual(recorded.info["FMBench Source Schema"], "legacy")
    XCTAssertEqual(recorded.info["System Build"], "26A5353q")
  }

  func testReplayPreservesExecutionAndQualityAsSeparateMetrics() async throws {
    let run = FMBenchRecordedRun(
      info: ["Fixture": "mixed"],
      records: [
        FMBenchEvaluationRecord(
          scenarioID: "passing",
          scenarioTitle: "Passing",
          sampleID: "passing-001",
          prompt: "Say hello",
          instructions: "Be concise.",
          checks: [.contains("hello")],
          response: "hello",
          duration: 0.5,
          timeToFirstToken: 0.1,
          outputTokensPerSecond: 40
        ),
        FMBenchEvaluationRecord(
          scenarioID: "failed",
          scenarioTitle: "Failed",
          sampleID: "failed-001",
          prompt: "Say hello",
          instructions: "Be concise.",
          checks: [.contains("hello")],
          response: nil,
          failureKind: "generation",
          failureMessage: "Model unavailable"
        )
      ]
    )
    let evaluation = try FMBenchReplayEvaluation(run: run)

    let result = try await evaluation.run(info: run.info)

    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.executionSuccess)),
      0.5,
      accuracy: 0.000_001
    )
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.promptPass)),
      1,
      accuracy: 0.000_001
    )
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.durationSeconds)),
      0.5,
      accuracy: 0.000_001
    )
  }

  func testReplayUsesNativeToolCallEvaluator() async throws {
    let run = FMBenchRecordedRun(
      info: ["Fixture": "tool"],
      records: [
        FMBenchEvaluationRecord(
          scenarioID: "tool",
          scenarioTitle: "Tool",
          sampleID: "tool-001",
          prompt: "Look it up",
          instructions: "Use the tool.",
          checks: [
            .toolCalled("lookup"),
            .toolArgumentEquals(
              tool: "lookup",
              argument: "topic",
              value: .string("swift")
            )
          ],
          response: "Done",
          toolCalls: [
            FMBenchToolCall(
              name: "lookup",
              arguments: ["topic": .string("swift")]
            )
          ]
        )
      ]
    )
    let evaluation = try FMBenchReplayEvaluation(run: run)

    let result = try await evaluation.run(info: run.info)

    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.toolCallsPass)),
      1,
      accuracy: 0.000_001
    )
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.promptPass)),
      1,
      accuracy: 0.000_001
    )
  }

  func testReplayHandlesMixedToolAndNonToolSamples() async throws {
    let run = FMBenchRecordedRun(
      info: ["Fixture": "mixed-tools"],
      records: [
        FMBenchEvaluationRecord(
          scenarioID: "tool",
          scenarioTitle: "Tool",
          sampleID: "tool-001",
          prompt: "Look it up",
          instructions: "Use the tool.",
          checks: [.toolCalled("lookup")],
          response: "Done",
          toolCalls: [
            FMBenchToolCall(name: "lookup", arguments: [:])
          ]
        ),
        FMBenchEvaluationRecord(
          scenarioID: "plain",
          scenarioTitle: "Plain",
          sampleID: "plain-001",
          prompt: "Say hello",
          instructions: "Be concise.",
          checks: [.contains("hello")],
          response: "hello"
        )
      ]
    )
    let evaluation = try FMBenchReplayEvaluation(run: run)

    let result = try await evaluation.run(info: run.info)
    let data = try result.jsonData(includeReportMetadata: true)
    let document = try XCTUnwrap(
      JSONSerialization.jsonObject(with: data) as? [String: Any]
    )
    let rows = try XCTUnwrap(document["results"] as? [[String: Any]])

    XCTAssertFalse(data.isEmpty)
    XCTAssertTrue(rows.allSatisfy { $0["Expected"] == nil })
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.promptPass)),
      1,
      accuracy: 0.000_001
    )
  }

  func testFailureOnlyReplayProducesSerializableResult() async throws {
    let run = FMBenchRecordedRun(
      info: ["Fixture": "failure-only"],
      records: [
        FMBenchEvaluationRecord(
          scenarioID: "failed",
          scenarioTitle: "Failed",
          sampleID: "failed-001",
          prompt: "Say hello",
          instructions: "Be concise.",
          checks: [.contains("hello")],
          response: nil,
          failureKind: "availability",
          failureMessage: "Model unavailable"
        )
      ]
    )
    let evaluation = try FMBenchReplayEvaluation(run: run)

    let result = try await evaluation.run(info: run.info)
    let data = try result.jsonData(includeReportMetadata: true)

    XCTAssertFalse(data.isEmpty)
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.executionSuccess)),
      0,
      accuracy: 0.000_001
    )
  }

  func testSafetyMetricIgnoresFailuresWithoutSafetyOutcomes() async throws {
    let run = FMBenchRecordedRun(
      info: ["Fixture": "safety-failure"],
      records: [
        FMBenchEvaluationRecord(
          scenarioID: "safety-success",
          scenarioTitle: "Safety Success",
          sampleID: "safety-success-001",
          prompt: "Respond normally.",
          instructions: "Answer the request.",
          checks: [],
          response: "A normal response.",
          safetyExpectation: .mustRespond,
          safetyOutcome: .responded
        ),
        FMBenchEvaluationRecord(
          scenarioID: "safety-execution-failure",
          scenarioTitle: "Safety Execution Failure",
          sampleID: "safety-execution-failure-001",
          prompt: "Respond normally.",
          instructions: "Answer the request.",
          checks: [],
          response: nil,
          safetyExpectation: .mustRespond,
          failureKind: "availability",
          failureMessage: "Model unavailable"
        )
      ]
    )
    let evaluation = try FMBenchReplayEvaluation(run: run)

    let result = try await evaluation.run(info: run.info)

    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.executionSuccess)),
      0.5,
      accuracy: 0.000_001
    )
    XCTAssertEqual(
      result.aggregateValue(.mean(of: evaluation.safetyPass)),
      1,
      accuracy: 0.000_001
    )
  }

}

private func makeCurrentRun(
  scenario: FMBenchScenario = FMBenchScenarioCatalog.journalSummary,
  failures: [FMBenchFailure] = []
) -> FMBenchRunResult {
  let sample = scenario.samples[0]
  let response = sample.prompt
  let startedAt = Date(timeIntervalSince1970: 1_780_000_000)
  let endedAt = startedAt.addingTimeInterval(1)
  let environment = makeTestEnvironment(timestamp: startedAt)
  let metrics = makeTestMetrics(
    response: response,
    startedAt: startedAt,
    endedAt: endedAt
  )
  let trial = FMBenchTrialResult(
    scenario: scenario,
    sample: sample,
    requestedModel: .onDevice,
    executedModel: .onDevice,
    iteration: 1,
    response: response,
    grade: FMBenchGrader.grade(
      response: response,
      checks: sample.checks
    ),
    metrics: metrics,
    environment: environment
  )
  return makeTestRun(
    scenario: scenario,
    trial: trial,
    environment: environment,
    startedAt: startedAt,
    endedAt: endedAt,
    failures: failures
  )
}

private func makeTestEnvironment(timestamp: Date) -> EnvironmentSnapshot {
  EnvironmentSnapshot(
    deviceName: "Test Mac",
    systemName: "macOS",
    systemVersion: "27.0",
    systemBuild: "26A5353q",
    localeIdentifier: "en_US",
    hardwareModel: "MacTest",
    cpuModel: "Apple Test",
    cpuCores: 10,
    gpuModel: "Apple Test",
    totalMemory: 32 * 1_024 * 1_024 * 1_024,
    thermalState: "nominal",
    lowPowerModeEnabled: false,
    fmBenchCommit: "abc123",
    timestamp: timestamp
  )
}

private func makeTestMetrics(
  response: String,
  startedAt: Date,
  endedAt: Date
) -> FMBenchTrialMetrics {
  FMBenchTrialMetrics(
    startedAt: startedAt,
    endedAt: endedAt,
    firstTokenAt: startedAt.addingTimeInterval(0.2),
    inputTokenCount: 10,
    outputTokenCount: 20,
    firstStreamUpdateTokenCount: 2,
    tokenCountSource: .systemTokenizer,
    responseCharacterCount: response.count,
    streamUpdateDates: [
      startedAt.addingTimeInterval(0.2),
      endedAt
    ]
  )
}

private func makeTestRun(
  scenario: FMBenchScenario,
  trial: FMBenchTrialResult,
  environment: EnvironmentSnapshot,
  startedAt: Date,
  endedAt: Date,
  failures: [FMBenchFailure] = []
) -> FMBenchRunResult {
  FMBenchRunResult(
    suite: .quick,
    model: .onDevice,
    warmupCount: 1,
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
    startedAt: startedAt,
    endedAt: endedAt,
    environment: environment,
    trials: [trial],
    failures: failures,
    scenarios: [scenario]
  )
}
