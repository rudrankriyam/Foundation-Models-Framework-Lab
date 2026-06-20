import FMFBenchCore
import FMFBenchEvaluations
import Evaluations
import Foundation
import XCTest

@available(macOS 27.0, *)
final class FMFBenchEvaluationsTests: XCTestCase {
  func testConvertsScenarioCorpusToEvaluationSamples() throws {
    let samples = try FMFBenchEvaluationsAdapter.samples(
      for: FMFBenchScenarioCatalog.taskCapture
    )

    XCTAssertEqual(samples.count, 25)
    XCTAssertEqual(samples[0].recordID, "task-capture-001")
    XCTAssertNil(samples[0].expected)
    XCTAssertNotNil(samples[0].generationSchema)
  }

  func testCreatesToolCallEvaluatorForToolWorkloadsOnly() {
    XCTAssertNotNil(
      FMFBenchEvaluationsAdapter.toolCallEvaluator(
        for: FMFBenchScenarioCatalog.groundedExplanation
      )
    )
    XCTAssertNil(
      FMFBenchEvaluationsAdapter.toolCallEvaluator(
        for: FMFBenchScenarioCatalog.journalSummary
      )
    )
  }

  func testAgenticScenarioPreservesOrderedTrajectoryExpectations() throws {
    let samples = try FMFBenchEvaluationsAdapter.samples(
      for: FMFBenchScenarioCatalog.personalOrganizer
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

  func testLoadsCurrentFMFBenchResult() throws {
    let run = makeCurrentRun()
    let data = try XCTUnwrap(
      FMFBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMFBenchRecordedRunLoader.decode(
      data,
      sourceName: "current.json"
    )

    XCTAssertEqual(recorded.records.count, 1)
    XCTAssertEqual(recorded.records[0].sampleID, run.trials[0].sample.id)
    XCTAssertEqual(recorded.info["FMFBench Source Schema"], "current")
    XCTAssertEqual(recorded.info["FMFBench Source File"], "current.json")
  }

  func testCurrentResultExcludesWarmupFailures() throws {
    let run = makeCurrentRun(
      failures: [
        FMFBenchFailure(
          scenarioID: "__warmup__",
          sampleID: "__warmup__-1",
          iteration: 1,
          kind: "availability",
          message: "Warmup failed"
        ),
        FMFBenchFailure(
          scenarioID: FMFBenchScenarioCatalog.journalSummary.id,
          sampleID: FMFBenchScenarioCatalog.journalSummary.samples[0].id,
          iteration: 2,
          kind: "generation",
          message: "Measured trial failed"
        )
      ]
    )
    let data = try XCTUnwrap(
      FMFBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMFBenchRecordedRunLoader.decode(data)

    XCTAssertEqual(recorded.records.count, 2)
    XCTAssertFalse(recorded.records.contains { $0.scenarioID == "__warmup__" })
    XCTAssertEqual(
      recorded.records.count(where: { !$0.executionSucceeded }),
      1
    )
  }

  func testCurrentSafetyFailurePreservesRecordedOutcome() throws {
    let scenario = FMFBenchScenarioCatalog.guardrailExpectedProtection
    let sample = scenario.samples[0]
    let run = makeCurrentRun(
      scenario: scenario,
      failures: [
        FMFBenchFailure(
          scenarioID: scenario.id,
          sampleID: sample.id,
          iteration: 2,
          kind: "guardrail",
          message: "Generation was blocked"
        )
      ]
    )
    let data = try XCTUnwrap(
      FMFBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMFBenchRecordedRunLoader.decode(data)
    let failure = try XCTUnwrap(
      recorded.records.first { !$0.executionSucceeded }
    )

    XCTAssertEqual(failure.safetyExpectation, .mustProtect)
    XCTAssertEqual(failure.safetyOutcome, .guardrailViolation)
  }

  func testCurrentFailurePreservesToolCallsAndFinalState() throws {
    let scenario = FMFBenchScenarioCatalog.personalOrganizer
    let sample = scenario.samples[0]
    let finalState = FMFBenchStateSnapshot(
      values: ["reminders.count": .integer(1)]
    )
    let run = makeCurrentRun(
      scenario: scenario,
      failures: [
        FMFBenchFailure(
          scenarioID: scenario.id,
          sampleID: sample.id,
          iteration: 2,
          kind: "generation",
          message: "Response was empty",
          toolCalls: [
            FMFBenchToolCall(
              name: "createReminder",
              arguments: ["title": .string("Call Maya Chen")]
            )
          ],
          finalState: finalState
        )
      ]
    )
    let data = try XCTUnwrap(
      FMFBenchReport(result: run).json().data(using: .utf8)
    )

    let recorded = try FMFBenchRecordedRunLoader.decode(data)
    let failure = try XCTUnwrap(
      recorded.records.first { !$0.executionSucceeded }
    )

    XCTAssertEqual(failure.toolCalls.map(\.name), ["createReminder"])
    XCTAssertEqual(
      failure.toolCalls[0].arguments["title"],
      .string("Call Maya Chen")
    )
    XCTAssertEqual(failure.finalState, finalState)
  }

  func testLiveStatefulEvaluatorsUseSuppliedFinalState() async throws {
    let scenario = makeStatefulEvaluationScenario()
    let sample = try XCTUnwrap(
      FMFBenchEvaluationsAdapter.samples(for: scenario).first
    )
    let subject = ModelSubject(
      value: "Created",
      transcript: StructuredTranscript()
    )
    let finalState = FMFBenchStateSnapshot(
      values: ["reminders.count": .integer(1)]
    )
    let provider: FMFBenchFinalStateProvider = { _ in finalState }

    let promptMetrics = try await FMFBenchEvaluationsAdapter.promptPassEvaluator(
      for: scenario,
      finalStateProvider: provider
    ).metrics(subject: subject, input: sample)
    let constraintMetrics = try await FMFBenchEvaluationsAdapter.constraintScoreEvaluator(
      for: scenario,
      finalStateProvider: provider
    ).metrics(subject: subject, input: sample)

    XCTAssertEqual(promptMetrics.first?.value, .passing)
    XCTAssertEqual(constraintMetrics.first?.value, .scoring(1))
  }

  func testLiveStatefulEvaluatorsIgnoreMissingFinalState() async throws {
    let scenario = makeStatefulEvaluationScenario()
    let sample = try XCTUnwrap(
      FMFBenchEvaluationsAdapter.samples(for: scenario).first
    )
    let subject = ModelSubject(
      value: "Created",
      transcript: StructuredTranscript()
    )

    let metrics = try await FMFBenchEvaluationsAdapter.promptPassEvaluator(
      for: scenario
    ).metrics(subject: subject, input: sample)

    XCTAssertEqual(metrics.first?.value, .ignore)
  }

  func testLoadsLegacyFMFBenchResult() throws {
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
          "fmfBenchCommit": "abc123"
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

    let recorded = try FMFBenchRecordedRunLoader.decode(
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
    XCTAssertEqual(recorded.info["FMFBench Source Schema"], "legacy")
    XCTAssertEqual(recorded.info["System Build"], "26A5353q")
  }

  func testReplayPreservesExecutionAndQualityAsSeparateMetrics() async throws {
    let run = FMFBenchRecordedRun(
      info: ["Fixture": "mixed"],
      records: [
        FMFBenchEvaluationRecord(
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
        FMFBenchEvaluationRecord(
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
    let evaluation = try FMFBenchReplayEvaluation(run: run)

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
    let run = FMFBenchRecordedRun(
      info: ["Fixture": "tool"],
      records: [
        FMFBenchEvaluationRecord(
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
            FMFBenchToolCall(
              name: "lookup",
              arguments: ["topic": .string("swift")]
            )
          ]
        )
      ]
    )
    let evaluation = try FMFBenchReplayEvaluation(run: run)

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
    let run = FMFBenchRecordedRun(
      info: ["Fixture": "mixed-tools"],
      records: [
        FMFBenchEvaluationRecord(
          scenarioID: "tool",
          scenarioTitle: "Tool",
          sampleID: "tool-001",
          prompt: "Look it up",
          instructions: "Use the tool.",
          checks: [.toolCalled("lookup")],
          response: "Done",
          toolCalls: [
            FMFBenchToolCall(name: "lookup", arguments: [:])
          ]
        ),
        FMFBenchEvaluationRecord(
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
    let evaluation = try FMFBenchReplayEvaluation(run: run)

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
    let run = FMFBenchRecordedRun(
      info: ["Fixture": "failure-only"],
      records: [
        FMFBenchEvaluationRecord(
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
    let evaluation = try FMFBenchReplayEvaluation(run: run)

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
    let run = FMFBenchRecordedRun(
      info: ["Fixture": "safety-failure"],
      records: [
        FMFBenchEvaluationRecord(
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
        FMFBenchEvaluationRecord(
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
    let evaluation = try FMFBenchReplayEvaluation(run: run)

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

private func makeStatefulEvaluationScenario() -> FMFBenchScenario {
  FMFBenchScenario(
    id: "stateful-evaluation",
    title: "Stateful evaluation",
    summary: "Verifies final-state evaluation plumbing.",
    category: .agenticToolUse,
    inspiredBy: ["FMFBench"],
    instructions: "Create the requested reminder.",
    prompt: "Create a reminder.",
    outputMode: .text,
    maximumResponseTokens: 32,
    checks: [
      .contains("Created"),
      .stateEquals(path: "reminders.count", value: .integer(1))
    ]
  )
}

private func makeCurrentRun(
  scenario: FMFBenchScenario = FMFBenchScenarioCatalog.journalSummary,
  failures: [FMFBenchFailure] = []
) -> FMFBenchRunResult {
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
  let trial = FMFBenchTrialResult(
    scenario: scenario,
    sample: sample,
    requestedModel: .onDevice,
    executedModel: .onDevice,
    iteration: 1,
    response: response,
    grade: FMFBenchGrader.grade(
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
    fmfBenchCommit: "abc123",
    timestamp: timestamp
  )
}

private func makeTestMetrics(
  response: String,
  startedAt: Date,
  endedAt: Date
) -> FMFBenchTrialMetrics {
  FMFBenchTrialMetrics(
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
  scenario: FMFBenchScenario,
  trial: FMFBenchTrialResult,
  environment: EnvironmentSnapshot,
  startedAt: Date,
  endedAt: Date,
  failures: [FMFBenchFailure] = []
) -> FMFBenchRunResult {
  FMFBenchRunResult(
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
