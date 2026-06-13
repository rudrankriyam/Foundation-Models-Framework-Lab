import AppBenchCore
import Evaluations
import FoundationModels

@available(macOS 27.0, *)
public enum AppBenchEvaluationsAdapter {
  public static let promptPassMetric = Metric("AppBench Prompt Pass")
  public static let constraintScoreMetric = Metric("AppBench Constraint Score")
  public static let toolCallsPassMetric = Metric("AppBench Tool Calls Pass")
  public static let toolCallsPercentageMetric = Metric("AppBench Tool Calls Percentage")

  public static func samples(
    for scenario: AppBenchScenario
  ) throws -> [AppBenchEvaluationSample] {
    let schema: GenerationSchema?
    switch scenario.outputMode {
    case .text:
      schema = nil
    case .guided(let appBenchSchema):
      schema = try AppBenchSchemaFactory.make(appBenchSchema)
    }

    return try scenario.samples.map { sample in
      AppBenchEvaluationSample(
        recordID: sample.id,
        prompt: try appBenchPrompt(for: sample),
        instructions: Instructions(scenario.instructions),
        generationSchema: schema,
        expectations: trajectoryExpectation(for: sample.checks)
      )
    }
  }

  public static func promptPassEvaluator(
    for scenario: AppBenchScenario
  ) -> Evaluator<AppBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return promptPassMetric.ignore(rationale: "Missing AppBench sample metadata.")
      }
      let grade = AppBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.appBenchToolCalls
      )
      return grade.promptPassed
        ? promptPassMetric.passing()
        : promptPassMetric.failing(rationale: failedCheckRationale(grade))
    }
  }

  public static func constraintScoreEvaluator(
    for scenario: AppBenchScenario
  ) -> Evaluator<AppBenchEvaluationSample> {
    let checks = checksBySampleID(scenario)
    return Evaluator { input, subject in
      guard let sampleChecks = checks[input.recordID] else {
        return constraintScoreMetric.ignore(
          rationale: "Missing AppBench sample metadata."
        )
      }
      let grade = AppBenchGrader.grade(
        response: subject.value,
        checks: sampleChecks,
        toolCalls: subject.appBenchToolCalls
      )
      return constraintScoreMetric.scoring(
        grade.score,
        rationale: failedCheckRationale(grade)
      )
    }
  }

  public static func toolCallEvaluator(
    for scenario: AppBenchScenario
  ) -> ToolCallEvaluator<AppBenchEvaluationSample>? {
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
    for checks: [AppBenchCheck]
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
    _ scenario: AppBenchScenario
  ) -> [String: [AppBenchCheck]] {
    Dictionary(uniqueKeysWithValues: scenario.samples.map { ($0.id, $0.checks) })
  }

  private static func argumentValue(_ value: AppBenchJSONValue) -> ArgumentValue {
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

  private static func failedCheckRationale(_ grade: AppBenchGrade) -> String? {
    let failures = grade.checks.filter { !$0.passed }.map(\.label)
    return failures.isEmpty ? nil : failures.joined(separator: "; ")
  }
}

@available(macOS 27.0, *)
extension ModelSubject where Value == String {
  fileprivate var appBenchToolCalls: [AppBenchToolCall] {
    toolCalls.compactMap { call in
      guard case .structure(let properties, _) = call.arguments.kind else {
        return nil
      }
      let arguments = properties.compactMapValues(\.appBenchJSONValue)
      return AppBenchToolCall(name: call.toolName, arguments: arguments)
    }
  }
}

@available(macOS 27.0, *)
extension GeneratedContent {
  fileprivate var appBenchJSONValue: AppBenchJSONValue? {
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
