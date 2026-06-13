import AppBenchCore
import Foundation

struct LegacyRunDocument: Decodable {
  let suite: AppBenchSuite
  let model: AppBenchModel
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
  let model: AppBenchModel
  let iteration: Int
  let response: String
  let metrics: LegacyMetrics
}

struct LegacyScenario: Decodable {
  let id: String
  let title: String
  let instructions: String
  let prompt: String
  let checks: [AppBenchCheck]
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
  let appBenchCommit: String?
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
      "AppBench Suite": suite,
      "AppBench Model": model,
      "AppBench Warmups": String(warmupCount),
      "AppBench Repetitions": String(repetitions),
      "AppBench Started": startedAt.formatted(.iso8601),
      "AppBench Ended": endedAt.formatted(.iso8601),
      "AppBench Source Schema": schema,
      "Evaluation Mode": "Recorded replay; no second model inference"
    ]
    if let sourceName {
      info["AppBench Source File"] = sourceName
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
  let appBenchCommit: String?

  init(_ environment: EnvironmentSnapshot) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    appBenchCommit = environment.appBenchCommit
  }

  init(_ environment: LegacyEnvironment) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    appBenchCommit = environment.appBenchCommit
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
    values["AppBench Commit"] = appBenchCommit
    return values.filter { !$0.value.isEmpty }
  }
}
