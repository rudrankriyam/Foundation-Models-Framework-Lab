import Darwin
import FMFBenchCore
import Foundation

@available(macOS 27.0, *)
public struct FMFBenchBridgeSubjectiveQualityJudge {
  public let descriptorPath: String
  public let modelIdentifier: String
  public let maximumCompletionTokens: Int
  public let temperature: Double

  public init(
    descriptorPath: String = "\(NSHomeDirectory())/.afm/bridge/connection.json",
    modelIdentifier: String = "pcc",
    maximumCompletionTokens: Int = 384,
    temperature: Double = 0
  ) {
    self.descriptorPath = descriptorPath
    self.modelIdentifier = modelIdentifier
    self.maximumCompletionTokens = maximumCompletionTokens
    self.temperature = temperature
  }

  public func run(
    run: FMFBenchRecordedRun,
    source: String? = nil
  ) async throws -> FMFBenchBridgeSubjectiveQualityReport {
    let records = FMFBenchSubjectiveQualityEvaluation.eligibleRecords(in: run)
    guard !records.isEmpty else {
      throw FMFBenchSubjectiveQualityError.noEligibleSamples
    }

    let client = try FMFBenchBridgeClient(
      descriptorPath: descriptorPath,
      requiredModelIdentifier: modelIdentifier
    )
    var results: [FMFBenchBridgeSubjectiveQualityReport.SampleResult] = []
    var totalTokenCount = 0

    for record in records {
      let response = try await client.chat(
        request: .init(
          model: modelIdentifier,
          messages: [
            .init(role: "user", content: Self.prompt(for: record))
          ],
          temperature: temperature,
          maxCompletionTokens: maximumCompletionTokens
        )
      )
      let choice = try response.firstChoice()
      let verdict = try Self.decodeVerdict(from: choice.message.content)
      totalTokenCount += response.usage.totalTokens
      results.append(
        .init(
          recordID: record.id,
          scenarioID: record.scenarioID,
          scenarioTitle: record.scenarioTitle,
          sampleID: record.sampleID,
          requestedModel: record.requestedModel,
          executedModel: record.executedModel,
          scores: verdict.scores,
          rationale: verdict.rationale,
          rawJudgeResponse: choice.message.content,
          tokenUsage: .init(
            inputTokens: response.usage.promptTokens,
            outputTokens: response.usage.completionTokens,
            totalTokens: response.usage.totalTokens
          )
        )
      )
    }

    return .init(
      source: source,
      judge: "PrivateCloudComputeLanguageModel via Foundation Lab Agent Bridge",
      modelIdentifier: modelIdentifier,
      descriptorPath: descriptorPath,
      endpoint: client.endpointDescription,
      sampleCount: results.count,
      totalTokenCount: totalTokenCount,
      results: results
    )
  }

  private static func prompt(for record: FMFBenchEvaluationRecord) -> String {
    """
    You are judging a recorded FMFBench response for subjective quality.

    The deterministic FMFBench grader has already checked exact constraints, \
    structured values, tool trajectory, safety gates, and final state where \
    applicable. Score only subjective quality for the requested app-shaped task.

    Return only valid JSON with this exact shape:
    {
      "scores": {
        "helpfulness": 1,
        "clarity": 1,
        "completeness": 1
      },
      "rationale": "One concise sentence."
    }

    Use integer scores from 1 to 4:
    4 = excellent, 3 = good with minor gaps, 2 = noticeably weak, 1 = poor.

    Scenario: \(record.scenarioTitle)
    Scenario ID: \(record.scenarioID)
    Sample ID: \(record.sampleID)
    Requested model: \(record.requestedModel)
    Executed model: \(record.executedModel)

    User prompt:
    \(record.prompt)

    Instructions:
    \(record.instructions)

    Deterministic checks already passed:
    \(record.checks.map(\.label).joined(separator: "\n"))

    Response to judge:
    \(record.response ?? "")
    """
  }

  private static func decodeVerdict(from response: String) throws -> BridgeJudgeVerdict {
    let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
    let jsonText: Substring
    if trimmed.first == "{", trimmed.last == "}" {
      jsonText = trimmed[trimmed.startIndex..<trimmed.endIndex]
    } else if let start = trimmed.firstIndex(of: "{"),
              let end = trimmed.lastIndex(of: "}") {
      jsonText = trimmed[start...end]
    } else {
      throw FMFBenchBridgeJudgeError.invalidJudgeJSON
    }

    let data = Data(String(jsonText).utf8)
    let verdict = try JSONDecoder().decode(BridgeJudgeVerdict.self, from: data)
    try verdict.validate()
    return verdict
  }
}

@available(macOS 27.0, *)
public struct FMFBenchBridgeSubjectiveQualityReport: Encodable {
  public struct Scores: Codable, Sendable {
    public let helpfulness: Double
    public let clarity: Double
    public let completeness: Double
  }

  public struct TokenUsage: Encodable, Sendable {
    public let inputTokens: Int
    public let outputTokens: Int
    public let totalTokens: Int
  }

  public struct SampleResult: Encodable, Sendable {
    public let recordID: String
    public let scenarioID: String
    public let scenarioTitle: String
    public let sampleID: String
    public let requestedModel: String
    public let executedModel: String
    public let scores: Scores
    public let rationale: String
    public let rawJudgeResponse: String
    public let tokenUsage: TokenUsage
  }

  public struct Aggregate: Encodable, Sendable {
    public let meanHelpfulness: Double
    public let meanClarity: Double
    public let meanCompleteness: Double
  }

  public let schemaVersion = "fmfbench-bridge-subjective-quality/v1"
  public let createdAt: Date
  public let source: String?
  public let judge: String
  public let modelIdentifier: String
  public let descriptorPath: String
  public let endpoint: String
  public let sampleCount: Int
  public let totalTokenCount: Int
  public let aggregate: Aggregate
  public let results: [SampleResult]

  public init(
    createdAt: Date = .now,
    source: String?,
    judge: String,
    modelIdentifier: String,
    descriptorPath: String,
    endpoint: String,
    sampleCount: Int,
    totalTokenCount: Int,
    results: [SampleResult]
  ) {
    self.createdAt = createdAt
    self.source = source
    self.judge = judge
    self.modelIdentifier = modelIdentifier
    self.descriptorPath = descriptorPath
    self.endpoint = endpoint
    self.sampleCount = sampleCount
    self.totalTokenCount = totalTokenCount
    self.results = results
    aggregate = Self.aggregate(results)
  }

  public func saveJSON(to directory: URL) throws -> URL {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let stamp = formatter.string(from: createdAt)
      .replacingOccurrences(of: ":", with: "-")
    let url = directory.appending(
      path: "FMFBenchBridgeSubjectiveQuality-\(stamp).json"
    )
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(self).write(to: url, options: .atomic)
    return url
  }

  private static func aggregate(_ results: [SampleResult]) -> Aggregate {
    func mean(_ keyPath: KeyPath<Scores, Double>) -> Double {
      guard !results.isEmpty else { return 0 }
      let total = results.reduce(0) { $0 + $1.scores[keyPath: keyPath] }
      return total / Double(results.count)
    }
    return .init(
      meanHelpfulness: mean(\.helpfulness),
      meanClarity: mean(\.clarity),
      meanCompleteness: mean(\.completeness)
    )
  }
}

private struct BridgeJudgeVerdict: Decodable {
  let scores: FMFBenchBridgeSubjectiveQualityReport.Scores
  let rationale: String

  func validate() throws {
    for score in [scores.helpfulness, scores.clarity, scores.completeness] {
      guard (1...4).contains(score) else {
        throw FMFBenchBridgeJudgeError.invalidJudgeScore(score)
      }
    }
    guard !rationale.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw FMFBenchBridgeJudgeError.invalidJudgeJSON
    }
  }
}

private struct FMFBenchBridgeClient {
  let endpointDescription: String

  private let baseURL: URL
  private let bearerToken: String

  init(
    descriptorPath: String,
    requiredModelIdentifier: String
  ) throws {
    let descriptorURL = URL(fileURLWithPath: descriptorPath).standardizedFileURL
    let descriptor = try JSONDecoder().decode(
      FMFBenchBridgeDescriptor.self,
      from: Data(contentsOf: descriptorURL)
    )
    try descriptor.validate(requiredModelIdentifier: requiredModelIdentifier)
    baseURL = try descriptor.endpoint.baseURL()
    endpointDescription = descriptor.endpoint.description
    bearerToken = descriptor.bearerToken
  }

  func chat(
    request: FMFBenchBridgeChatRequest
  ) async throws -> FMFBenchBridgeChatResponse {
    let body = try JSONEncoder().encode(request)
    var urlRequest = URLRequest(url: baseURL.appending(path: "v1/chat/completions"))
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = body
    urlRequest.timeoutInterval = 120
    urlRequest.cachePolicy = .reloadIgnoringLocalCacheData
    urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    urlRequest.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

    let (data, response) = try await URLSession.shared.data(for: urlRequest)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw FMFBenchBridgeJudgeError.invalidBridgeResponse
    }
    guard (200..<300).contains(httpResponse.statusCode) else {
      let message = String(data: data, encoding: .utf8) ?? "Bridge request failed."
      throw FMFBenchBridgeJudgeError.bridgeFailure(
        statusCode: httpResponse.statusCode,
        message: message
      )
    }
    return try JSONDecoder().decode(FMFBenchBridgeChatResponse.self, from: data)
  }
}

private struct FMFBenchBridgeDescriptor: Decodable {
  let version: Int
  let endpoint: FMFBenchBridgeEndpoint
  let bearerToken: String
  let processIdentifier: Int32
  let modelIdentifiers: [String]

  func validate(requiredModelIdentifier: String) throws {
    guard version == 1 else {
      throw FMFBenchBridgeJudgeError.invalidDescriptor("Unsupported version \(version).")
    }
    guard Darwin.kill(processIdentifier, 0) == 0 || errno == EPERM else {
      throw FMFBenchBridgeJudgeError.staleDescriptor
    }
    guard modelIdentifiers.contains(requiredModelIdentifier) else {
      throw FMFBenchBridgeJudgeError.modelUnavailable(requiredModelIdentifier)
    }
  }
}

private enum FMFBenchBridgeEndpoint: Decodable, CustomStringConvertible {
  case loopbackTCP(host: String, port: Int)

  func baseURL() throws -> URL {
    switch self {
    case .loopbackTCP(let host, let port):
      var components = URLComponents()
      components.scheme = "http"
      components.host = host
      components.port = port
      guard let url = components.url else {
        throw FMFBenchBridgeJudgeError.invalidDescriptor(
          "Could not construct bridge endpoint URL."
        )
      }
      return url
    }
  }

  var description: String {
    switch self {
    case .loopbackTCP(let host, let port):
      "http://\(host):\(port)"
    }
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let value = try container.nestedContainer(
      keyedBy: LoopbackTCPKeys.self,
      forKey: .loopbackTCP
    )
    self = .loopbackTCP(
      host: try value.decode(String.self, forKey: .host),
      port: try value.decode(Int.self, forKey: .port)
    )
  }

  private enum CodingKeys: String, CodingKey {
    case loopbackTCP
  }

  private enum LoopbackTCPKeys: String, CodingKey {
    case host
    case port
  }
}

private struct FMFBenchBridgeChatRequest: Encodable {
  struct Message: Encodable {
    let role: String
    let content: String
  }

  let model: String
  let messages: [Message]
  let temperature: Double
  let maxCompletionTokens: Int

  private enum CodingKeys: String, CodingKey {
    case model
    case messages
    case temperature
    case maxCompletionTokens = "max_completion_tokens"
  }
}

private struct FMFBenchBridgeChatResponse: Decodable {
  struct Choice: Decodable {
    struct Message: Decodable {
      let content: String
    }

    let message: Message
  }

  struct Usage: Decodable {
    let promptTokens: Int
    let completionTokens: Int
    let totalTokens: Int

    private enum CodingKeys: String, CodingKey {
      case promptTokens = "prompt_tokens"
      case completionTokens = "completion_tokens"
      case totalTokens = "total_tokens"
    }
  }

  let choices: [Choice]
  let usage: Usage

  func firstChoice() throws -> Choice {
    guard let choice = choices.first else {
      throw FMFBenchBridgeJudgeError.invalidBridgeResponse
    }
    return choice
  }
}

@available(macOS 27.0, *)
public enum FMFBenchBridgeJudgeError: LocalizedError {
  case staleDescriptor
  case invalidDescriptor(String)
  case modelUnavailable(String)
  case invalidBridgeResponse
  case bridgeFailure(statusCode: Int, message: String)
  case invalidJudgeJSON
  case invalidJudgeScore(Double)

  public var errorDescription: String? {
    switch self {
    case .staleDescriptor:
      """
      The Foundation Lab Agent Bridge descriptor is stale. Launch the signed \
      Foundation Lab macOS app with Agent Bridge enabled, then retry.
      """
    case .invalidDescriptor(let message):
      "The Foundation Lab Agent Bridge descriptor is invalid: \(message)"
    case .modelUnavailable(let model):
      "The Foundation Lab Agent Bridge does not expose the \(model) model."
    case .invalidBridgeResponse:
      "Foundation Lab Agent Bridge returned an invalid response."
    case .bridgeFailure(let statusCode, let message):
      "Foundation Lab Agent Bridge request failed with HTTP \(statusCode): \(message)"
    case .invalidJudgeJSON:
      "The bridge judge did not return the expected JSON verdict."
    case .invalidJudgeScore(let score):
      "The bridge judge returned an invalid score: \(score)."
    }
  }
}
