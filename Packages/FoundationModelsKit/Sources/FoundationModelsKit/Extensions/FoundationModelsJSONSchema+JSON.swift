import Foundation

extension FoundationModelsJSONSchema {
  /// Returns deterministic, validated JSON data suitable for hashing or token estimation.
  public func jsonData(pretty: Bool = false) throws -> Data {
    try validate()
    let encoder = JSONEncoder()
    encoder.outputFormatting = pretty ? [.prettyPrinted, .sortedKeys] : [.sortedKeys]
    return try encoder.encode(self)
  }

  /// Returns deterministic, validated JSON text suitable for prompts or token estimation.
  public func jsonString(pretty: Bool = false) throws -> String {
    let data = try jsonData(pretty: pretty)
    guard let string = String(data: data, encoding: .utf8) else {
      throw FoundationModelsJSONSchemaError(
        kind: .invalidSchema,
        path: "$",
        message: "Could not encode the schema as UTF-8 JSON."
      )
    }
    return string
  }
}
