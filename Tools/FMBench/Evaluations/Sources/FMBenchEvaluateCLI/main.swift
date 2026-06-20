import FMBenchEvaluations
import Evaluations
import Foundation

@available(macOS 27.0, *)
@main
struct FMBenchEvaluateCLI {
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
      fputs("fmbench-evaluate: \(error.localizedDescription)\n", stderr)
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
    let input = try parser.requiredPath(label: "FMBench JSON result")
    try parser.finish()

    let output =
      outputOption.map(expandedURL)
      ?? input.deletingLastPathComponent().appending(path: "Evaluations")
    let run = try FMBenchRecordedRunLoader.load(from: input)
    let evaluation = try FMBenchReplayEvaluation(run: run)
    let result = try await evaluation.run(info: run.info)

    try FileManager.default.createDirectory(
      at: output,
      withIntermediateDirectories: true
    )
    let resultURL = try result.saveJSON(
      to: output,
      includeReportMetadata: includeReportMetadata
    )

    switch format {
    case .text:
      print("Replayed \(run.records.count) recorded FMBench sample(s).")
      print("Evaluation result: \(resultURL.path)")
      print("Inspect with: xceval inspect \(resultURL.path)")
    case .json:
      try printJSON(
        ReplayPayload(
          source: input.path,
          sampleCount: run.records.count,
          evaluationResult: resultURL.path,
          evaluationInfo: run.info
        )
      )
    }
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
        fmbench-evaluate replay <fmbench.json> [--output <directory>]
            [--no-report-metadata] [--format text|json]

      Replays recorded FMBench responses through Apple Evaluations without
      running the model again. Use the standalone xceval CLI to inspect,
      stream, compare, or export the resulting artifacts.
      """
    )
  }
}

private struct ReplayPayload: Encodable {
  let schemaVersion = "fmbench-evaluate/v1"
  let command = "replay"
  let source: String
  let sampleCount: Int
  let evaluationResult: String
  let evaluationInfo: [String: String]
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
    return FMBenchEvaluateCLI.expandedURL(arguments[index])
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

private enum CLIError: LocalizedError {
  case unknownCommand(String)
  case missingArgument(String)
  case missingValue(String)
  case unknownArgument(String)
  case invalidFormat(String)
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
    case .invalidUTF8:
      "The replay result could not be encoded as UTF-8."
    }
  }
}
