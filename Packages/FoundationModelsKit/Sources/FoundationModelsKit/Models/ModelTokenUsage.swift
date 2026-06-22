import Foundation
import FoundationModels

/// A stable, serializable projection of Foundation Models token accounting.
///
/// `observed` values come from a completed model response. `tokenized` values
/// come from `SystemLanguageModel.tokenCount(for:)` without running generation,
/// and `estimated` values come from FoundationModelsKit's calibrated fallback.
public struct ModelTokenUsage: Codable, Hashable, Sendable {
  public enum Measurement: String, Codable, Hashable, Sendable {
    case observed
    case tokenized
    case estimated
  }

  public enum Scope: String, Codable, Hashable, Sendable {
    /// Tokens attributable to one completed generation.
    case response
    /// Tokens accumulated across every generation in one session.
    case session
    /// Tokens currently present in supplied prompt or transcript context.
    case context
  }

  public struct Input: Codable, Hashable, Sendable {
    public let totalTokenCount: Int
    public let cachedTokenCount: Int?

    public init(totalTokenCount: Int, cachedTokenCount: Int? = nil) {
      self.totalTokenCount = max(0, totalTokenCount)
      self.cachedTokenCount = cachedTokenCount.map { max(0, $0) }
    }
  }

  public struct Output: Codable, Hashable, Sendable {
    public let totalTokenCount: Int
    public let reasoningTokenCount: Int?

    public init(totalTokenCount: Int, reasoningTokenCount: Int? = nil) {
      self.totalTokenCount = max(0, totalTokenCount)
      self.reasoningTokenCount = reasoningTokenCount.map { max(0, $0) }
    }
  }

  public let input: Input
  public let output: Output?
  public let measurement: Measurement
  public let scope: Scope

  public var totalTokenCount: Int {
    input.totalTokenCount + (output?.totalTokenCount ?? 0)
  }

  public init(
    input: Input,
    output: Output? = nil,
    measurement: Measurement,
    scope: Scope
  ) {
    self.input = input
    self.output = output
    self.measurement = measurement
    self.scope = scope
  }

  public init(inputTokenCount: Int, measurement: Measurement, scope: Scope = .context) {
    self.init(
      input: Input(totalTokenCount: inputTokenCount),
      measurement: measurement,
      scope: scope
    )
  }

  private enum CodingKeys: String, CodingKey {
    case input
    case output
    case measurement
    case scope
    case totalTokenCount
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(input, forKey: .input)
    try container.encodeIfPresent(output, forKey: .output)
    try container.encode(measurement, forKey: .measurement)
    try container.encode(scope, forKey: .scope)
    try container.encode(totalTokenCount, forKey: .totalTokenCount)
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      input: try container.decode(Input.self, forKey: .input),
      output: try container.decodeIfPresent(Output.self, forKey: .output),
      measurement: try container.decode(Measurement.self, forKey: .measurement),
      scope: try container.decode(Scope.self, forKey: .scope)
    )
  }
}

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
public extension ModelTokenUsage {
  /// Creates an observed usage value from Foundation Models runtime metrics.
  init(observing usage: LanguageModelSession.Usage, scope: Scope = .response) {
    self.init(
      input: Input(
        totalTokenCount: usage.input.totalTokenCount,
        cachedTokenCount: usage.input.cachedTokenCount
      ),
      output: Output(
        totalTokenCount: usage.output.totalTokenCount,
        reasoningTokenCount: usage.output.reasoningTokenCount
      ),
      measurement: .observed,
      scope: scope
    )
  }
}
#endif
