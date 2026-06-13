import AppBenchCore
import Evaluations
import Foundation
import FoundationModels

@available(macOS 27.0, *)
public struct AppBenchReplayEvaluation: Evaluation {
  public let executionSuccess = Metric("AppBench Execution Success")
  public let promptPass = Metric("AppBench Prompt Pass")
  public let constraintScore = Metric("AppBench Constraint Score")
  public let safetyPass = Metric("AppBench Safety Pass")
  public let durationSeconds = Metric("AppBench Duration Seconds")
  public let timeToFirstTokenSeconds = Metric("AppBench TTFT Seconds")
  public let outputTokensPerSecond = Metric("AppBench Output Tokens Per Second")
  public let peakResidentMemoryMiB = Metric("AppBench Peak Resident Memory MiB")
  public let toolCallsPass = Metric("AppBench Tool Calls Pass")
  public let toolCallsPercentage = Metric("AppBench Tool Calls Percentage")

  public let dataset: ArrayLoader<AppBenchEvaluationSample>
  public let run: AppBenchRecordedRun
  private let recordsByID: [String: AppBenchEvaluationRecord]
  private let includesPromptQuality: Bool
  private let includesSafety: Bool
  private let includesDuration: Bool
  private let includesTimeToFirstToken: Bool
  private let includesThroughput: Bool
  private let includesMemory: Bool
  private let includesToolExpectations: Bool

  public init(run: AppBenchRecordedRun) throws {
    guard !run.records.isEmpty else {
      throw AppBenchReplayEvaluationError.emptyRun
    }

    self.run = run
    recordsByID = Dictionary(
      uniqueKeysWithValues: run.records.map { ($0.id, $0) }
    )
    includesPromptQuality = run.records.contains {
      $0.executionSucceeded && $0.response != nil && !$0.checks.isEmpty
    }
    includesSafety = run.records.contains {
      $0.safetyExpectation != nil && $0.safetyOutcome != .notApplicable
    }
    includesDuration = run.records.contains { $0.duration != nil }
    includesTimeToFirstToken = run.records.contains { $0.timeToFirstToken != nil }
    includesThroughput = run.records.contains { $0.outputTokensPerSecond != nil }
    includesMemory = run.records.contains {
      $0.peakObservedResidentMemoryBytes != nil
    }
    includesToolExpectations = run.records.contains { record in
      AppBenchEvaluationsAdapter.trajectoryExpectation(for: record.checks) != nil
    }
    dataset = ArrayLoader(
      samples: run.records.map { record in
        AppBenchEvaluationSample(
          recordID: record.id,
          prompt: Prompt(record.prompt),
          instructions: Instructions(record.instructions),
          expectations: AppBenchEvaluationsAdapter.trajectoryExpectation(
            for: record.checks
          )
        )
      }
    )
  }

  public func subject(
    from sample: AppBenchEvaluationSample
  ) async throws -> ModelSubject<String> {
    let record = try record(for: sample)
    let transcript = try StructuredTranscript(
      toolCalls: record.toolCalls.enumerated().map { index, call in
        Transcript.ToolCall(
          id: "\(record.id)-tool-\(index)",
          toolName: call.name,
          arguments: try generatedContent(for: call.arguments)
        )
      },
      instructionText: record.instructions,
      prompts: [record.prompt]
    )
    return ModelSubject(
      value: record.response ?? "",
      transcript: transcript
    )
  }

  public var evaluators: Evaluators {
    var evaluators: Evaluators = []

    evaluators.append(
      Evaluator { input, _ in
        let record = try record(for: input)
        if record.executionSucceeded {
          return executionSuccess.passing()
        }
        return executionSuccess.failing(
          rationale: [record.failureKind, record.failureMessage]
            .compactMap(\.self)
            .joined(separator: ": ")
        )
      })

    evaluators.append(
      Evaluator { input, _ in
        let record = try record(for: input)
        guard record.executionSucceeded, let response = record.response else {
          return promptPass.ignore(rationale: "No response was produced.")
        }
        guard !record.checks.isEmpty else {
          return promptPass.ignore(rationale: "This workload has no quality checks.")
        }
        let grade = AppBenchGrader.grade(
          response: response,
          checks: record.checks,
          toolCalls: record.toolCalls
        )
        return grade.promptPassed
          ? promptPass.passing()
          : promptPass.failing(rationale: failedCheckRationale(grade))
      })

    evaluators.append(
      Evaluator { input, _ in
        let record = try record(for: input)
        guard record.executionSucceeded, let response = record.response else {
          return constraintScore.ignore(rationale: "No response was produced.")
        }
        guard !record.checks.isEmpty else {
          return constraintScore.ignore(
            rationale: "This workload has no quality checks."
          )
        }
        let grade = AppBenchGrader.grade(
          response: response,
          checks: record.checks,
          toolCalls: record.toolCalls
        )
        return constraintScore.scoring(
          grade.score,
          rationale: failedCheckRationale(grade)
        )
      })

    evaluators.append(
      Evaluator { input, _ in
        let record = try record(for: input)
        guard let expectation = record.safetyExpectation else {
          return safetyPass.ignore(rationale: "Not a safety sample.")
        }
        guard record.safetyOutcome != .notApplicable else {
          return safetyPass.ignore(rationale: "No safety outcome was recorded.")
        }
        guard
          let passed = AppBenchSafetyClassifier.passed(
            expectation: expectation,
            outcome: record.safetyOutcome
          )
        else {
          return safetyPass.ignore(rationale: "No safety outcome was recorded.")
        }
        let rationale =
          "Expected \(expectation.rawValue); observed \(record.safetyOutcome.rawValue)."
        return passed
          ? safetyPass.passing(rationale: rationale)
          : safetyPass.failing(rationale: rationale)
      })

    evaluators.append(
      scoringEvaluator(
        metric: durationSeconds,
        value: \.duration,
        missingRationale: "Duration was not recorded."
      ))

    evaluators.append(
      scoringEvaluator(
        metric: timeToFirstTokenSeconds,
        value: \.timeToFirstToken,
        missingRationale: "TTFT was not recorded."
      ))

    evaluators.append(
      scoringEvaluator(
        metric: outputTokensPerSecond,
        value: \.outputTokensPerSecond,
        missingRationale: "Token throughput was not recorded."
      ))

    evaluators.append(
      scoringEvaluator(
        metric: peakResidentMemoryMiB,
        value: { record in
          record.peakObservedResidentMemoryBytes.map {
            Double($0) / 1_048_576
          }
        },
        missingRationale: "Peak resident memory was not recorded."
      ))

    if includesToolExpectations {
      evaluators.append(
        ToolCallEvaluator(
          allPass: toolCallsPass,
          percentagePass: toolCallsPercentage
        ))
    }

    return evaluators
  }

  public func aggregateMetrics(using aggregator: inout MetricsAggregator) {
    aggregator.group("Execution") { group in
      group.computeMean(of: executionSuccess)
    }
    if includesPromptQuality || includesSafety || includesToolExpectations {
      aggregator.group("Quality") { group in
        if includesPromptQuality {
          group.computeMean(of: promptPass)
          group.computeMean(of: constraintScore)
        }
        if includesSafety {
          group.computeMean(of: safetyPass)
        }
        if includesToolExpectations {
          group.computeMean(of: toolCallsPass)
          group.computeMean(of: toolCallsPercentage)
        }
      }
    }
    if includesDuration || includesTimeToFirstToken {
      aggregator.group("Latency") { group in
        if includesDuration {
          group.computeMean(of: durationSeconds)
          group.computeMedian(of: durationSeconds)
          group.computeMaximum(of: durationSeconds)
        }
        if includesTimeToFirstToken {
          group.computeMean(of: timeToFirstTokenSeconds)
          group.computeMedian(of: timeToFirstTokenSeconds)
          group.computeMaximum(of: timeToFirstTokenSeconds)
        }
      }
    }
    if includesThroughput {
      aggregator.group("Throughput") { group in
        group.computeMean(of: outputTokensPerSecond)
        group.computeMedian(of: outputTokensPerSecond)
      }
    }
    if includesMemory {
      aggregator.group("Resources") { group in
        group.computeMean(of: peakResidentMemoryMiB)
        group.computeMaximum(of: peakResidentMemoryMiB)
      }
    }
  }
}

@available(macOS 27.0, *)
extension AppBenchReplayEvaluation {
  private func record(
    for sample: AppBenchEvaluationSample
  ) throws -> AppBenchEvaluationRecord {
    guard let record = recordsByID[sample.recordID] else {
      throw AppBenchReplayEvaluationError.missingRecord(sample.recordID)
    }
    return record
  }

  private func scoringEvaluator(
    metric: Metric,
    value: @escaping @Sendable (AppBenchEvaluationRecord) -> Double?,
    missingRationale: String
  ) -> Evaluator<AppBenchEvaluationSample> {
    Evaluator { input, _ in
      let record = try record(for: input)
      guard let score = value(record) else {
        return metric.ignore(rationale: missingRationale)
      }
      return metric.scoring(score)
    }
  }

  private func generatedContent(
    for arguments: [String: AppBenchJSONValue]
  ) throws -> GeneratedContent {
    let object = arguments.mapValues(\.jsonObject)
    let data = try JSONSerialization.data(
      withJSONObject: object,
      options: [.sortedKeys]
    )
    guard let json = String(data: data, encoding: .utf8) else {
      throw AppBenchReplayEvaluationError.invalidToolArguments
    }
    return try GeneratedContent(json: json)
  }

  private func failedCheckRationale(_ grade: AppBenchGrade) -> String? {
    let failures = grade.checks.filter { !$0.passed }.map(\.label)
    return failures.isEmpty ? nil : failures.joined(separator: "; ")
  }
}

public enum AppBenchReplayEvaluationError: LocalizedError {
  case emptyRun
  case missingRecord(String?)
  case invalidToolArguments

  public var errorDescription: String? {
    switch self {
    case .emptyRun:
      "The AppBench result contains no trials or failures."
    case .missingRecord(let id):
      "The evaluation sample does not map to an AppBench record: \(id ?? "missing ID")."
    case .invalidToolArguments:
      "The recorded tool arguments could not be converted to generated content."
    }
  }
}

extension AppBenchJSONValue {
  fileprivate var jsonObject: Any {
    switch self {
    case .string(let value):
      value
    case .integer(let value):
      value
    case .number(let value):
      value
    case .boolean(let value):
      value
    }
  }
}
