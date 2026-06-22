import Foundation

/// A validation or decoding failure in the supported Foundation Models JSON Schema dialect.
public struct FoundationModelsJSONSchemaError: Error, Sendable, Equatable, LocalizedError {
  /// The broad category of schema failure.
  public enum Kind: String, Sendable, Equatable {
    /// The document contains a JSON Schema keyword that this converter does not support.
    case unsupportedKeyword

    /// A supported keyword has an invalid value or is used in an invalid context.
    case invalidSchema
  }

  /// The broad category of schema failure.
  public let kind: Kind

  /// A stable JSONPath locating the invalid keyword or value.
  public let path: String

  /// A human-readable explanation of the failure.
  public let message: String

  public init(kind: Kind, path: String, message: String) {
    self.kind = kind
    self.path = path
    self.message = message
  }

  public var errorDescription: String? {
    "\(path): \(message)"
  }
}
