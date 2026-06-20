import FMBenchCore
import Evaluations
import FoundationModels

@available(macOS 27.0, *)
public enum FMBenchEvaluationsAdapter {
  public static let promptPassMetric = Metric("FMBench Prompt Pass")
  public static let constraintScoreMetric = Metric("FMBench Constraint Score")
  public static let toolCallsPassMetric = Metric("FMBench Tool Calls Pass")
  public static let toolCallsPercentageMetric = Metric("FMBench Tool Calls Percentage")

  public static func samples(
    for scenario: FMBenchScenario
  ) throws -> [FMBenchEvaluationSample] {
    let schema: GenerationSchema?
    switch scenario.outputMode {
    case .text:
      schema = nil
    case .guided(let fmBenchSchema):
      schema = try FMBenchSchemaFactory.make(fmBenchSchema)
    }

    return try scenario.samples.map { sample in
      FMBenchEvaluationSample(
        recordID: sample.id,
        prompt: try fmBenchPrompt(for: sample),
        instructions: Instructions(scenario.instructions),
        generationSchema: schema,
        expectations: trajectoryExpectation(for: sample.checks)
      )
    }
  }

  public static func promptPassEvaluator(
    for scenario: FMBenchScenario
  ) -> Evaluator<FMBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return promptPassMetric.ignore(rationale: "Missing FMBench sample metadata.")
      }
      let grade = FMBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.fmBenchToolCalls
      )
      return grade.promptPassed
        ? promptPassMetric.passing()
        : promptPassMetric.failing(rationale: failedCheckRationale(grade))
    }
  }

  public static func constraintScoreEvaluator(
    for scenario: FMBenchScenario
  ) -> Evaluator<FMBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return constraintScoreMetric.ignore(
          rationale: "Missing FMBench sample metadata."
        )
      }
      let grade = FMBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.fmBenchToolCalls
      )
      return constraintScoreMetric.scoring(
        grade.score,
        rationale: failedCheckRationale(grade)
      )
    }
  }

  public static func toolCallEvaluator(
    for scenario: FMBenchScenario
  ) -> ToolCallEvaluator<FMBenchEvaluationSample>? {
    guard scenario.samples.contains(where: { trajectoryExpectation(for: $0.checks) != nil })
    else {
      return nil
    }
    return ToolCallEvaluator(
      allPass: toolCallsPassMetric,
      percentagePass: toolCallsPercentageMetric
    )
  }

  static func trajectoryExpectation(
    for checks: [FMBenchCheck]
  ) -> TrajectoryExpectation? {
    var toolNames: [String] = []
    var argumentsByTool: [String: [ArgumentMatcher]] = [:]

    for check in checks {
      switch check {
      case .toolCalled(let name):
        if !toolNames.contains(name) {
          toolNames.append(name)
        }
      case .toolArgumentEquals(let tool, let argument, let value):
        if !toolNames.contains(tool) {
          toolNames.append(tool)
        }
        argumentsByTool[tool, default: []].append(
          .exact(argumentName: argument, value: argumentValue(value))
        )
      default:
        break
      }
    }

    guard !toolNames.isEmpty else { return nil }
    let expectations = toolNames.map { name in
      ToolExpectation(name, arguments: argumentsByTool[name] ?? [])
    }
    return TrajectoryExpectation(
      ordered: [],
      unordered: expectations,
      allowsAdditionalToolCalls: true
    )
  }

  private static func checksBySampleID(
    _ scenario: FMBenchScenario
  ) -> [String: [FMBenchCheck]] {
    Dictionary(uniqueKeysWithValues: scenario.samples.map { ($0.id, $0.checks) })
  }

  private static func argumentValue(_ value: FMBenchJSONValue) -> ArgumentValue {
    switch value {
    case .string(let value):
      .string(value)
    case .integer(let value):
      .int(value)
    case .number(let value):
      .double(value)
    case .boolean(let value):
      .bool(value)
    }
  }

  private static func failedCheckRationale(_ grade: FMBenchGrade) -> String? {
    let failures = grade.checks.filter { !$0.passed }.map(\.label)
    return failures.isEmpty ? nil : failures.joined(separator: "; ")
  }
}

@available(macOS 27.0, *)
extension ModelSubject where Value == String {
  fileprivate var fmBenchToolCalls: [FMBenchToolCall] {
    toolCalls.compactMap { call in
      guard case .structure(let properties, _) = call.arguments.kind else {
        return nil
      }
      let arguments = properties.compactMapValues(\.fmBenchJSONValue)
      return FMBenchToolCall(name: call.toolName, arguments: arguments)
    }
  }
}

@available(macOS 27.0, *)
extension GeneratedContent {
  fileprivate var fmBenchJSONValue: FMBenchJSONValue? {
    switch kind {
    case .string(let value):
      return .string(value)
    case .number(let value):
      if value.rounded() == value {
        return .integer(Int(value))
      }
      return .number(value)
    case .bool(let value):
      return .boolean(value)
    case .null, .array, .structure:
      return nil
    @unknown default:
      return nil
    }
  }
}
