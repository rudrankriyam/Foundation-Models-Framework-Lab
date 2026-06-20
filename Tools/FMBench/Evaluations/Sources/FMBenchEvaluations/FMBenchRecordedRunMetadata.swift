import FMBenchCore
import Foundation

struct LegacyRunDocument: Decodable {
  let suite: FMBenchSuite
  let model: FMBenchModel
  let warmupCount: Int
  let repetitions: Int
  let startedAt: Date
  let endedAt: Date
  let environment: LegacyEnvironment?
  let trials: [LegacyTrial]
  let failures: [LegacyFailure]
}

struct LegacyTrial: Decodable {
  let id: UUID
  let scenario: LegacyScenario
  let model: FMBenchModel
  let iteration: Int
  let response: String
  let metrics: LegacyMetrics
}

struct LegacyScenario: Decodable {
  let id: String
  let title: String
  let instructions: String
  let prompt: String
  let checks: [FMBenchCheck]
}

struct LegacyFailure: Decodable {
  let id: UUID
  let scenarioID: String
  let iteration: Int
  let message: String
}

struct LegacyMetrics: Decodable {
  let duration: TimeInterval?
  let timeToFirstToken: TimeInterval?
  let outputTokensPerSecond: Double?
  let peakObservedResidentMemoryBytes: UInt64?
}

struct LegacyEnvironment: Decodable {
  let deviceName: String?
  let systemName: String?
  let systemVersion: String?
  let systemBuild: String?
  let hardwareModel: String?
  let cpuModel: String?
  let fmBenchCommit: String?
}

struct RecordedRunInfo {
  let suite: String
  let model: String
  let warmupCount: Int
  let repetitions: Int
  let startedAt: Date
  let endedAt: Date
  let schema: String

  func dictionary(
    environment: EnvironmentInfo?,
    sourceName: String?
  ) -> [String: String] {
    var info = [
      "FMBench Suite": suite,
      "FMBench Model": model,
      "FMBench Warmups": String(warmupCount),
      "FMBench Repetitions": String(repetitions),
      "FMBench Started": startedAt.formatted(.iso8601),
      "FMBench Ended": endedAt.formatted(.iso8601),
      "FMBench Source Schema": schema,
      "Evaluation Mode": "Recorded replay; no second model inference"
    ]
    if let sourceName {
      info["FMBench Source File"] = sourceName
    }
    if let environment {
      info.merge(environment.dictionary) { _, new in new }
    }
    return info
  }
}

struct EnvironmentInfo {
  let deviceName: String?
  let systemName: String?
  let systemVersion: String?
  let systemBuild: String?
  let hardwareModel: String?
  let cpuModel: String?
  let fmBenchCommit: String?

  init(_ environment: EnvironmentSnapshot) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    fmBenchCommit = environment.fmBenchCommit
  }

  init(_ environment: LegacyEnvironment) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    fmBenchCommit = environment.fmBenchCommit
  }

  var dictionary: [String: String] {
    var values: [String: String] = [:]
    values["Device"] = deviceName
    values["System"] = [systemName, systemVersion]
      .compactMap(\.self)
      .joined(separator: " ")
    values["System Build"] = systemBuild
    values["Hardware Model"] = hardwareModel
    values["Chip"] = cpuModel
    values["FMBench Commit"] = fmBenchCommit
    return values.filter { !$0.value.isEmpty }
  }
}
