import Foundation
import FoundationModels

private let exactTokenSafetyBufferMultiplier = 0.05

public extension Transcript.Entry {
  /// Returns the model's exact token count when the API is available, otherwise an estimate.
  func tokenCount(using model: SystemLanguageModel = .default) async -> Int {
    await tokenUsage(using: model).totalTokenCount
  }

  /// Returns a token count together with whether it was tokenized or estimated.
  func tokenUsage(using model: SystemLanguageModel = .default) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let exactTokenCount = try? await model.tokenCount(for: [self]) {
      return ModelTokenUsage(inputTokenCount: exactTokenCount, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(inputTokenCount: estimatedTokenCount, measurement: .estimated)
  }
}

public extension Transcript {
  /// Returns the model's exact token count when the API is available, otherwise an estimate.
  func tokenCount(using model: SystemLanguageModel = .default) async -> Int {
    await tokenUsage(using: model).totalTokenCount
  }

  /// Returns a token count together with whether it was tokenized or estimated.
  func tokenUsage(using model: SystemLanguageModel = .default) async -> ModelTokenUsage {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let exactTokenCount = try? await model.tokenCount(for: Array(self)) {
      return ModelTokenUsage(inputTokenCount: exactTokenCount, measurement: .tokenized)
    }
    #endif

    return ModelTokenUsage(inputTokenCount: estimatedTokenCount, measurement: .estimated)
  }

  /// Returns an exact token count with a small buffer, or the conservative estimated count.
  func safeTokenCount(using model: SystemLanguageModel = .default) async -> Int {
    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let exactTokenCount = try? await model.tokenCount(for: Array(self)) {
      return exactTokenCount + Int(Double(exactTokenCount) * exactTokenSafetyBufferMultiplier)
    }
    #endif

    return safeEstimatedTokenCount
  }

  /// Checks a context limit using exact model tokenization when available.
  func isApproachingLimit(
    threshold: Double = 0.70,
    maxTokens: Int = 4096,
    using model: SystemLanguageModel = .default
  ) async -> Bool {
    let currentTokens = await safeTokenCount(using: model)
    return currentTokens > Int(Double(maxTokens) * threshold)
  }

  /// Keeps the newest transcript entries within a conservative token budget.
  ///
  /// The first instructions entry is always preserved, even when it alone
  /// exceeds the requested budget.
  func entriesWithinTokenBudget(
    _ budget: Int,
    using model: SystemLanguageModel = .default
  ) async -> [Transcript.Entry] {
    let instructions = first(where: \.isFoundationModelsKitInstruction)
    let conversation = filter { !$0.isFoundationModelsKitInstruction }

    #if compiler(>=6.3)
    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *),
       let exactWindow = await exactTokenBudgetWindow(
         instructions: instructions,
         conversation: conversation,
         budget: budget,
         model: model
       ) {
      return exactWindow
    }
    #endif

    return foundationModelsKitEstimatedEntriesWithinTokenBudget(budget)
  }
}

private extension Transcript.Entry {
  var isFoundationModelsKitInstruction: Bool {
    if case .instructions = self {
      return true
    }
    return false
  }
}

private extension Transcript {
  #if compiler(>=6.3)
  @available(iOS 26.4, macOS 26.4, visionOS 26.4, *)
  func exactTokenBudgetWindow(
    instructions: Transcript.Entry?,
    conversation: [Transcript.Entry],
    budget: Int,
    model: SystemLanguageModel
  ) async -> [Transcript.Entry]? {
    let base = instructions.map { [$0] } ?? []
    let contentBudget = Int(
      floor(Double(Swift.max(0, budget)) / (1 + exactTokenSafetyBufferMultiplier))
    )

    guard let baseTokens = base.isEmpty
      ? 0
      : try? await model.tokenCount(for: base)
    else {
      return nil
    }

    if baseTokens > contentBudget {
      return base
    }

    var low = 0
    var high = conversation.count

    while low < high {
      let midpoint = (low + high + 1) / 2
      let candidate = base + Array(conversation.suffix(midpoint))

      guard let candidateTokens = try? await model.tokenCount(for: candidate) else {
        return nil
      }

      if candidateTokens <= contentBudget {
        low = midpoint
      } else {
        high = midpoint - 1
      }
    }

    return base + Array(conversation.suffix(low))
  }
  #endif
}
