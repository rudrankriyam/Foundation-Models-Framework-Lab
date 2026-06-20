import FMFBenchCore
import Foundation

struct LegacyRunDocument: Decodable {
  let suite: FMFBenchSuite
  let model: FMFBenchModel
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
  let model: FMFBenchModel
  let iteration: Int
  let response: String
  let metrics: LegacyMetrics
}

struct LegacyScenario: Decodable {
  let id: String
  let title: String
  let instructions: String
  let prompt: String
  let checks: [FMFBenchCheck]
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
  let fmfBenchCommit: String?
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
      "FMFBench Suite": suite,
      "FMFBench Model": model,
      "FMFBench Warmups": String(warmupCount),
      "FMFBench Repetitions": String(repetitions),
      "FMFBench Started": startedAt.formatted(.iso8601),
      "FMFBench Ended": endedAt.formatted(.iso8601),
      "FMFBench Source Schema": schema,
      "Evaluation Mode": "Recorded replay; no second model inference"
    ]
    if let sourceName {
      info["FMFBench Source File"] = sourceName
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
  let fmfBenchCommit: String?

  init(_ environment: EnvironmentSnapshot) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    fmfBenchCommit = environment.fmfBenchCommit
  }

  init(_ environment: LegacyEnvironment) {
    deviceName = environment.deviceName
    systemName = environment.systemName
    systemVersion = environment.systemVersion
    systemBuild = environment.systemBuild
    hardwareModel = environment.hardwareModel
    cpuModel = environment.cpuModel
    fmfBenchCommit = environment.fmfBenchCommit
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
    values["FMFBench Commit"] = fmfBenchCommit
    return values.filter { !$0.value.isEmpty }
  }
}
