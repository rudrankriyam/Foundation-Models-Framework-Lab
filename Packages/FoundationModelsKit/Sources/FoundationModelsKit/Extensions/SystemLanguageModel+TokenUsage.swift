import FoundationModels

public extension SystemLanguageModel {
  /// Counts a prompt with Apple's tokenizer when available, otherwise uses the
  /// package's calibrated text estimator.
  func tokenUsage(
    for prompt: Prompt,
    estimatedFrom fallbackText: String
  ) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let count = try? await tokenCount(for: prompt) {
      return ModelTokenUsage(inputTokenCount: count, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(
      inputTokenCount: estimateTokens(from: fallbackText),
      measurement: .estimated
    )
  }

  /// Counts instructions with Apple's tokenizer when available, otherwise
  /// uses the package's calibrated text estimator.
  func tokenUsage(
    for instructions: Instructions,
    estimatedFrom fallbackText: String
  ) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let count = try? await tokenCount(for: instructions) {
      return ModelTokenUsage(inputTokenCount: count, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(
      inputTokenCount: estimateTokens(from: fallbackText),
      measurement: .estimated
    )
  }

  /// Counts tool definitions with Apple's tokenizer when available, otherwise
  /// estimates from their serialized manifests.
  func tokenUsage(
    for tools: [any Tool],
    estimatedFrom fallbackText: String
  ) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let count = try? await tokenCount(for: tools) {
      return ModelTokenUsage(inputTokenCount: count, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(
      inputTokenCount: estimateTokens(from: fallbackText),
      measurement: .estimated
    )
  }

  /// Counts a generation schema with Apple's tokenizer when available,
  /// otherwise estimates from the serialized schema document.
  func tokenUsage(
    for schema: GenerationSchema,
    estimatedFrom fallbackText: String
  ) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let count = try? await tokenCount(for: schema) {
      return ModelTokenUsage(inputTokenCount: count, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(
      inputTokenCount: estimateTokens(from: fallbackText),
      measurement: .estimated
    )
  }
}
