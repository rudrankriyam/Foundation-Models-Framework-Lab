import AppBenchCore
import Foundation

public struct AppBenchRecordedRun: Sendable {
  public let info: [String: String]
  public let records: [AppBenchEvaluationRecord]

  public init(
    info: [String: String],
    records: [AppBenchEvaluationRecord]
  ) {
    self.info = info
    self.records = records
  }
}

public struct AppBenchEvaluationRecord: Sendable {
  public let id: String
  public let scenarioID: String
  public let scenarioTitle: String
  public let sampleID: String
  public let prompt: String
  public let instructions: String
  public let checks: [AppBenchCheck]
  public let response: String?
  public let toolCalls: [AppBenchToolCall]
  public let safetyExpectation: AppBenchSafetyExpectation?
  public let safetyOutcome: AppBenchSafetyOutcome
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
    checks: [AppBenchCheck],
    response: String?,
    toolCalls: [AppBenchToolCall] = [],
    safetyExpectation: AppBenchSafetyExpectation? = nil,
    safetyOutcome: AppBenchSafetyOutcome = .notApplicable,
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

public enum AppBenchRecordedRunLoader {
  public static func load(from url: URL) throws -> AppBenchRecordedRun {
    try decode(
      Data(contentsOf: url),
      sourceName: url.lastPathComponent
    )
  }

  public static func decode(
    _ data: Data,
    sourceName: String? = nil
  ) throws -> AppBenchRecordedRun {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      let result = try decoder.decode(AppBenchRunResult.self, from: data)
      return currentRun(result, sourceName: sourceName)
    } catch let currentError {
      do {
        let result = try decoder.decode(LegacyRunDocument.self, from: data)
        return legacyRun(result, sourceName: sourceName)
      } catch let legacyError {
        throw AppBenchRecordedRunError.invalidDocument(
          currentSchemaError: currentError.localizedDescription,
          legacySchemaError: legacyError.localizedDescription
        )
      }
    }
  }

  private static func currentRun(
    _ result: AppBenchRunResult,
    sourceName: String?
  ) -> AppBenchRecordedRun {
    let scenarios = Dictionary(
      uniqueKeysWithValues: AppBenchScenarioCatalog.all.map { ($0.id, $0) }
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

    return AppBenchRecordedRun(
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
  ) -> AppBenchRecordedRun {
    let catalog = Dictionary(
      uniqueKeysWithValues: AppBenchScenarioCatalog.all.map { ($0.id, $0) }
    )
    let measuredFailures = result.failures.filter {
      $0.scenarioID != "__warmup__"
    }
    let records =
      result.trials.map(legacyRecord)
      + measuredFailures.map {
        legacyFailureRecord(
          $0,
          model: result.model,
          scenarios: catalog
        )
      }

    return AppBenchRecordedRun(
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
    _ trial: AppBenchTrialResult,
    scenarios: [String: AppBenchScenario]
  ) -> AppBenchEvaluationRecord {
    let scenario = scenarios[trial.scenarioID]
    return AppBenchEvaluationRecord(
      id: trial.id.uuidString,
      scenarioID: trial.scenarioID,
      scenarioTitle: trial.scenarioTitle,
      sampleID: trial.sample.id,
      prompt: trial.sample.prompt,
      instructions: scenario?.instructions ?? "",
      checks: trial.sample.checks,
      response: trial.response,
      toolCalls: trial.toolCalls,
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
    _ failure: AppBenchFailure,
    model: AppBenchModel,
    scenarios: [String: AppBenchScenario]
  ) -> AppBenchEvaluationRecord {
    let scenario = scenarios[failure.scenarioID]
    let sample = scenario?.samples.first { $0.id == failure.sampleID }
    return AppBenchEvaluationRecord(
      id: failure.id.uuidString,
      scenarioID: failure.scenarioID,
      scenarioTitle: scenario?.title ?? failure.scenarioID,
      sampleID: failure.sampleID,
      prompt: sample?.prompt
        ?? "Execution failed before prompt metadata was recorded.",
      instructions: scenario?.instructions ?? "",
      checks: sample?.checks ?? [],
      response: nil,
      safetyExpectation: sample?.safetyExpectation,
      iteration: failure.iteration,
      requestedModel: model.rawValue,
      executedModel: model.rawValue,
      failureKind: failure.kind,
      failureMessage: failure.message
    )
  }

  private static func legacyRecord(
    _ trial: LegacyTrial
  ) -> AppBenchEvaluationRecord {
    AppBenchEvaluationRecord(
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
    model: AppBenchModel,
    scenarios: [String: AppBenchScenario]
  ) -> AppBenchEvaluationRecord {
    let scenario = scenarios[failure.scenarioID]
    return AppBenchEvaluationRecord(
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

public enum AppBenchRecordedRunError: LocalizedError {
  case invalidDocument(currentSchemaError: String, legacySchemaError: String)

  public var errorDescription: String? {
    switch self {
    case .invalidDocument(let currentError, let legacyError):
      """
      The file is not a supported AppBench result.
      Current schema: \(currentError)
      Legacy schema: \(legacyError)
      """
    }
  }
}
