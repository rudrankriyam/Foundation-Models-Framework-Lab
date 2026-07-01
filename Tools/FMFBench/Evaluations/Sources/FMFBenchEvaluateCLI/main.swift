import FMFBenchEvaluations
import Evaluations
import Foundation

@available(macOS 27.0, *)
@main
struct FMFBenchEvaluateCLI {
  static func main() async {
    do {
      let arguments = Array(CommandLine.arguments.dropFirst())
      guard let command = arguments.first else {
        printUsage()
        exit(1)
      }

      switch command {
      case "replay":
        try await replay(Array(arguments.dropFirst()))
      case "help", "--help", "-h":
        printUsage()
      default:
        throw CLIError.unknownCommand(command)
      }
    } catch {
      fputs("fmfbench-evaluate: \(error.localizedDescription)\n", stderr)
      exit(1)
    }
  }

  private static func replay(_ arguments: [String]) async throws {
    var parser = ArgumentParser(arguments)
    let format = try OutputFormat(
      parser.option("--format") ?? "text"
    )
    let outputOption = try parser.option("--output")
    let includeReportMetadata = !parser.flag("--no-report-metadata")
    let judge = try SubjectiveJudgeOption(parser.option("--judge") ?? "none")
    let input = try parser.requiredPath(label: "FMFBench JSON result")
    try parser.finish()

    let output =
      outputOption.map(expandedURL)
      ?? input.deletingLastPathComponent().appending(path: "Evaluations")
    let run = try FMFBenchRecordedRunLoader.load(from: input)
    let evaluation = try FMFBenchReplayEvaluation(run: run)
    let result = try await evaluation.run(info: run.info)

    try FileManager.default.createDirectory(
      at: output,
      withIntermediateDirectories: true
    )
    let resultURL = try result.saveJSON(
      to: output,
      includeReportMetadata: includeReportMetadata
    )
    let subjective = try await subjectiveResult(
      for: run,
      judge: judge,
      output: output,
      includeReportMetadata: includeReportMetadata
    )

    switch format {
    case .text:
      print("Replayed \(run.records.count) recorded FMFBench sample(s).")
      print("Evaluation result: \(resultURL.path)")
      if let subjective {
        print(
          "Subjective \(subjective.judge) judge result "
            + "(\(subjective.sampleCount) sample(s)): \(subjective.resultURL.path)"
        )
      } else if judge != .none {
        print("Subjective judge skipped: no eligible deterministic-passing samples.")
      }
      print("Inspect with: xceval inspect \(resultURL.path)")
    case .json:
      try printJSON(
        ReplayPayload(
          source: input.path,
          sampleCount: run.records.count,
          evaluationResult: resultURL.path,
          evaluationInfo: run.info,
          subjectiveJudge: subjective?.judge,
          subjectiveSampleCount: subjective?.sampleCount ?? 0,
          subjectiveEvaluationResult: subjective?.resultURL.path
        )
      )
    }
  }

  private static func subjectiveResult(
    for run: FMFBenchRecordedRun,
    judge: SubjectiveJudgeOption,
    output: URL,
    includeReportMetadata: Bool
  ) async throws -> SubjectiveReplayResult? {
    let eligibleRecords = FMFBenchSubjectiveQualityEvaluation.eligibleRecords(in: run)
    guard !eligibleRecords.isEmpty else { return nil }

    guard judge == .privateCloudCompute else { return nil }
    let evaluation = try FMFBenchSubjectiveQualityEvaluation(
      run: run,
      judge: .privateCloudCompute
    )
    var info = run.info
    info["FMFBench Evaluation Mode"] =
      "Subjective quality; deterministic-passing non-safety samples only"
    info["FMFBench Judge Model"] = evaluation.judge.displayName

    let result = try await evaluation.run(info: info)
    let resultURL = try result.saveJSON(
      to: output,
      includeReportMetadata: includeReportMetadata
    )
    return SubjectiveReplayResult(
      judge: evaluation.judge.displayName,
      sampleCount: eligibleRecords.count,
      resultURL: resultURL
    )
  }

  fileprivate static func expandedURL(_ path: String) -> URL {
    URL(
      fileURLWithPath: (path as NSString).expandingTildeInPath
    ).standardizedFileURL
  }

  private static func printJSON<T: Encodable>(_ value: T) throws {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [
      .prettyPrinted,
      .sortedKeys,
      .withoutEscapingSlashes
    ]
    let data = try encoder.encode(value)
    guard let output = String(data: data, encoding: .utf8) else {
      throw CLIError.invalidUTF8
    }
    print(output)
  }

  private static func printUsage() {
    print(
      """
      Usage:
        fmfbench-evaluate replay <fmfbench.json> [--output <directory>]
            [--judge none|pcc] [--no-report-metadata] [--format text|json]

      Replays recorded FMFBench responses through Apple Evaluations without
      running the model again. Use the standalone xceval CLI to inspect,
      stream, compare, or export the resulting artifacts.

      --judge pcc writes an additional subjective-quality artifact. It uses
      PrivateCloudComputeLanguageModel as a model judge and only sends
      successful, deterministic-passing, non-safety responses to save quota.
      """
    )
  }
}

private struct SubjectiveReplayResult {
  let judge: String
  let sampleCount: Int
  let resultURL: URL
}

private struct ReplayPayload: Encodable {
  let schemaVersion = "fmfbench-evaluate/v1"
  let command = "replay"
  let source: String
  let sampleCount: Int
  let evaluationResult: String
  let evaluationInfo: [String: String]
  let subjectiveJudge: String?
  let subjectiveSampleCount: Int
  let subjectiveEvaluationResult: String?
}

private struct ArgumentParser {
  private let arguments: [String]
  private var consumed: Set<Int> = []

  init(_ arguments: [String]) {
    self.arguments = arguments
  }

  mutating func requiredPath(label: String) throws -> URL {
    guard
      let index = arguments.indices.first(where: {
        !consumed.contains($0) && !arguments[$0].hasPrefix("-")
      })
    else {
      throw CLIError.missingArgument(label)
    }
    consumed.insert(index)
    return FMFBenchEvaluateCLI.expandedURL(arguments[index])
  }

  mutating func option(_ name: String) throws -> String? {
    guard
      let index = arguments.indices.first(where: {
        !consumed.contains($0) && arguments[$0] == name
      })
    else {
      return nil
    }
    consumed.insert(index)
    let valueIndex = arguments.index(after: index)
    guard
      arguments.indices.contains(valueIndex),
      !arguments[valueIndex].hasPrefix("--")
    else {
      throw CLIError.missingValue(name)
    }
    consumed.insert(valueIndex)
    return arguments[valueIndex]
  }

  mutating func flag(_ name: String) -> Bool {
    guard
      let index = arguments.indices.first(where: {
        !consumed.contains($0) && arguments[$0] == name
      })
    else {
      return false
    }
    consumed.insert(index)
    return true
  }

  func finish() throws {
    if let index = arguments.indices.first(where: {
      !consumed.contains($0)
    }) {
      throw CLIError.unknownArgument(arguments[index])
    }
  }
}

private enum OutputFormat: String {
  case text
  case json

  init(_ value: String) throws {
    guard let format = Self(rawValue: value) else {
      throw CLIError.invalidFormat(value)
    }
    self = format
  }
}

private enum SubjectiveJudgeOption: String {
  case none
  case privateCloudCompute

  init(_ value: String) throws {
    switch value {
    case "none":
      self = .none
    case "pcc":
      self = .privateCloudCompute
    default:
      throw CLIError.invalidJudge(value)
    }
  }
}

private enum CLIError: LocalizedError {
  case unknownCommand(String)
  case missingArgument(String)
  case missingValue(String)
  case unknownArgument(String)
  case invalidFormat(String)
  case invalidJudge(String)
  case invalidUTF8

  var errorDescription: String? {
    switch self {
    case .unknownCommand(let command):
      "Unknown command '\(command)'."
    case .missingArgument(let label):
      "Missing \(label)."
    case .missingValue(let option):
      "Missing value for \(option)."
    case .unknownArgument(let argument):
      "Unknown argument '\(argument)'."
    case .invalidFormat(let value):
      "Unknown output format '\(value)'."
    case .invalidJudge(let value):
      "Unknown subjective judge '\(value)'. Use 'none' or 'pcc'."
    case .invalidUTF8:
      "The replay result could not be encoded as UTF-8."
    }
  }
}
