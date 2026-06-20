import FMBenchCore
import Foundation

public struct FMBenchRecordedRun: Sendable {
  public let info: [String: String]
  public let records: [FMBenchEvaluationRecord]

  public init(
    info: [String: String],
    records: [FMBenchEvaluationRecord]
  ) {
    self.info = info
    self.records = records
  }
}

public struct FMBenchEvaluationRecord: Sendable {
  public let id: String
  public let scenarioID: String
  public let scenarioTitle: String
  public let sampleID: String
  public let prompt: String
  public let instructions: String
  public let checks: [FMBenchCheck]
  public let response: String?
  public let toolCalls: [FMBenchToolCall]
  public let finalState: FMBenchStateSnapshot?
  public let safetyExpectation: FMBenchSafetyExpectation?
  public let safetyOutcome: FMBenchSafetyOutcome
  public let iteration: Int
  public let requestedModel: String
  public let executedModel: String
  public let failureKind: String?
  public let failureMessage: String?
  public let duration: TimeInterval?
  public let timeToFirstToken: TimeInterval?
  public let outputTokensPerSecond: Double?
  public let peakObservedResidentMemoryBytes: UInt64?

  public init(
    id: String = UUID().uuidString,
    scenarioID: String,
    scenarioTitle: String,
    sampleID: String,
    prompt: String,
    instructions: String,
    checks: [FMBenchCheck],
    response: String?,
    toolCalls: [FMBenchToolCall] = [],
    finalState: FMBenchStateSnapshot? = nil,
    safetyExpectation: FMBenchSafetyExpectation? = nil,
    safetyOutcome: FMBenchSafetyOutcome = .notApplicable,
    iteration: Int = 1,
    requestedModel: String = "unknown",
    executedModel: String = "unknown",
    failureKind: String? = nil,
    failureMessage: String? = nil,
    duration: TimeInterval? = nil,
    timeToFirstToken: TimeInterval? = nil,
    outputTokensPerSecond: Double? = nil,
    peakObservedResidentMemoryBytes: UInt64? = nil
  ) {
    self.id = id
    self.scenarioID = scenarioID
    self.scenarioTitle = scenarioTitle
    self.sampleID = sampleID
    self.prompt = prompt
    self.instructions = instructions
    self.checks = checks
    self.response = response
    self.toolCalls = toolCalls
    self.finalState = finalState
    self.safetyExpectation = safetyExpectation
    self.safetyOutcome = safetyOutcome
    self.iteration = iteration
    self.requestedModel = requestedModel
    self.executedModel = executedModel
    self.failureKind = failureKind
    self.failureMessage = failureMessage
    self.duration = duration
    self.timeToFirstToken = timeToFirstToken
    self.outputTokensPerSecond = outputTokensPerSecond
    self.peakObservedResidentMemoryBytes = peakObservedResidentMemoryBytes
  }

  public var executionSucceeded: Bool {
    failureMessage == nil
  }
}

public enum FMBenchRecordedRunLoader {
  public static func load(from url: URL) throws -> FMBenchRecordedRun {
    try decode(
      Data(contentsOf: url),
      sourceName: url.lastPathComponent
    )
  }

  public static func decode(
    _ data: Data,
    sourceName: String? = nil
  ) throws -> FMBenchRecordedRun {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      let result = try decoder.decode(FMBenchRunResult.self, from: data)
      return currentRun(result, sourceName: sourceName)
    } catch let currentError {
      do {
        let result = try decoder.decode(LegacyRunDocument.self, from: data)
        return legacyRun(result, sourceName: sourceName)
      } catch let legacyError {
        throw FMBenchRecordedRunError.invalidDocument(
          currentSchemaError: currentError.localizedDescription,
          legacySchemaError: legacyError.localizedDescription
        )
      }
    }
  }

  private static func currentRun(
    _ result: FMBenchRunResult,
    sourceName: String?
  ) -> FMBenchRecordedRun {
    let scenarios = Dictionary(
      uniqueKeysWithValues: FMBenchScenarioCatalog.all.map { ($0.id, $0) }
    )
    let measuredFailures = result.failures.filter {
      $0.scenarioID != "__warmup__"
    }
    let records =
      result.trials.map { currentRecord($0, scenarios: scenarios) }
      + measuredFailures.map {
        currentFailureRecord(
          $0,
          model: result.model,
          scenarios: scenarios
        )
      }

    return FMBenchRecordedRun(
      info: RecordedRunInfo(
        suite: result.suite.rawValue,
        model: result.model.rawValue,
        warmupCount: result.warmupCount,
        repetitions: result.repetitions,
        startedAt: result.startedAt,
        endedAt: result.endedAt,
        schema: "current"
      ).dictionary(
        environment: EnvironmentInfo(result.environment),
        sourceName: sourceName
      ),
      records: records
    )
  }

  private static func legacyRun(
    _ result: LegacyRunDocument,
    sourceName: String?
  ) -> FMBenchRecordedRun {
    let historicalScenarios = result.trials.reduce(
      into: [String: LegacyScenario]()
    ) { scenarios, trial in
      if scenarios[trial.scenario.id] == nil {
        scenarios[trial.scenario.id] = trial.scenario
      }
    }
    let measuredFailures = result.failures.filter {
      $0.scenarioID != "__warmup__"
    }
    let records =
      result.trials.map(legacyRecord)
      + measuredFailures.map {
        legacyFailureRecord(
          $0,
          model: result.model,
          scenarios: historicalScenarios
        )
      }

    return FMBenchRecordedRun(
      info: RecordedRunInfo(
        suite: result.suite.rawValue,
        model: result.model.rawValue,
        warmupCount: result.warmupCount,
        repetitions: result.repetitions,
        startedAt: result.startedAt,
        endedAt: result.endedAt,
        schema: "legacy"
      ).dictionary(
        environment: result.environment.map(EnvironmentInfo.init),
        sourceName: sourceName
      ),
      records: records
    )
  }

  private static func currentRecord(
    _ trial: FMBenchTrialResult,
    scenarios: [String: FMBenchScenario]
  ) -> FMBenchEvaluationRecord {
    let scenario = scenarios[trial.scenarioID]
    return FMBenchEvaluationRecord(
      id: trial.id.uuidString,
      scenarioID: trial.scenarioID,
      scenarioTitle: trial.scenarioTitle,
      sampleID: trial.sample.id,
      prompt: trial.sample.prompt,
      instructions: scenario?.instructions ?? "",
      checks: trial.sample.checks,
      response: trial.response,
      toolCalls: trial.toolCalls,
      finalState: trial.finalState,
      safetyExpectation: trial.sample.safetyExpectation,
      safetyOutcome: trial.safetyOutcome,
      iteration: trial.iteration,
      requestedModel: trial.requestedModel.rawValue,
      executedModel: trial.executedModel.rawValue,
      duration: trial.metrics.duration,
      timeToFirstToken: trial.metrics.timeToFirstToken,
      outputTokensPerSecond: trial.metrics.outputTokensPerSecond,
      peakObservedResidentMemoryBytes: trial.metrics
        .peakObservedResidentMemoryBytes
    )
  }

  private static func currentFailureRecord(
    _ failure: FMBenchFailure,
    model: FMBenchModel,
    scenarios: [String: FMBenchScenario]
  ) -> FMBenchEvaluationRecord {
    let scenario = scenarios[failure.scenarioID]
    let sample = scenario?.samples.first { $0.id == failure.sampleID }
    return FMBenchEvaluationRecord(
      id: failure.id.uuidString,
      scenarioID: failure.scenarioID,
      scenarioTitle: scenario?.title ?? failure.scenarioID,
      sampleID: failure.sampleID,
      prompt: sample?.prompt
        ?? "Execution failed before prompt metadata was recorded.",
      instructions: scenario?.instructions ?? "",
      checks: sample?.checks ?? [],
      response: nil,
      toolCalls: failure.toolCalls ?? [],
      finalState: failure.finalState,
      safetyExpectation: sample?.safetyExpectation,
      safetyOutcome: safetyOutcome(forFailureKind: failure.kind),
      iteration: failure.iteration,
      requestedModel: model.rawValue,
      executedModel: model.rawValue,
      failureKind: failure.kind,
      failureMessage: failure.message
    )
  }

  private static func safetyOutcome(
    forFailureKind failureKind: String
  ) -> FMBenchSafetyOutcome {
    switch failureKind {
    case "guardrail":
      .guardrailViolation
    case "refusal":
      .refusal
    default:
      .notApplicable
    }
  }

  private static func legacyRecord(
    _ trial: LegacyTrial
  ) -> FMBenchEvaluationRecord {
    FMBenchEvaluationRecord(
      id: trial.id.uuidString,
      scenarioID: trial.scenario.id,
      scenarioTitle: trial.scenario.title,
      sampleID: "\(trial.scenario.id)-legacy-\(trial.iteration)",
      prompt: trial.scenario.prompt,
      instructions: trial.scenario.instructions,
      checks: trial.scenario.checks,
      response: trial.response,
      iteration: trial.iteration,
      requestedModel: trial.model.rawValue,
      executedModel: trial.model.rawValue,
      duration: trial.metrics.duration,
      timeToFirstToken: trial.metrics.timeToFirstToken,
      outputTokensPerSecond: trial.metrics.outputTokensPerSecond,
      peakObservedResidentMemoryBytes: trial.metrics
        .peakObservedResidentMemoryBytes
    )
  }

  private static func legacyFailureRecord(
    _ failure: LegacyFailure,
    model: FMBenchModel,
    scenarios: [String: LegacyScenario]
  ) -> FMBenchEvaluationRecord {
    let scenario = scenarios[failure.scenarioID]
    return FMBenchEvaluationRecord(
      id: failure.id.uuidString,
      scenarioID: failure.scenarioID,
      scenarioTitle: scenario?.title ?? failure.scenarioID,
      sampleID: "\(failure.scenarioID)-legacy-failure",
      prompt: scenario?.prompt
        ?? "Execution failed before prompt metadata was recorded.",
      instructions: scenario?.instructions ?? "",
      checks: scenario?.checks ?? [],
      response: nil,
      iteration: failure.iteration,
      requestedModel: model.rawValue,
      executedModel: model.rawValue,
      failureKind: "execution",
      failureMessage: failure.message
    )
  }
}

public enum FMBenchRecordedRunError: LocalizedError {
  case invalidDocument(currentSchemaError: String, legacySchemaError: String)

  public var errorDescription: String? {
    switch self {
    case .invalidDocument(let currentError, let legacyError):
      """
      The file is not a supported FMBench result.
      Current schema: \(currentError)
      Legacy schema: \(legacyError)
      """
    }
  }
}
