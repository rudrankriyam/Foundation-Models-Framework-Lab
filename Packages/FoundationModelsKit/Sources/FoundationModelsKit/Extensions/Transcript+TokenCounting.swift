//
//  Transcript+TokenCounting.swift
//  FoundationModelsTools
//
//  Token counting and context window management utilities for Foundation Models transcripts.
//  Uses the package's calibrated character-ratio estimator.
//

import Foundation
import FoundationModels

// MARK: - Constants

/// Empirically calibrated: approximately 4.75 characters per token
/// Based on xctrace Foundation Models instrument measurements across diverse test cases.
/// Input: ~4.8 chars/token, Output: ~4.7 chars/token, Balanced: 4.75 chars/token
private let charactersPerToken = 4.75

/// Conservative estimation: Apple's original guidance of 4.5 characters per token
/// Use this for critical token budgets to avoid context overflow
private let conservativeCharactersPerToken = 4.5

/// Safety buffer multiplier for conservative token estimates (25%)
private let safetyBufferMultiplier = 0.25

/// System overhead in tokens for context window calculations
private let systemOverheadTokens = 100

/// Tool call overhead in tokens
private let toolCallOverheadTokens = 5

/// Tool definition framing overhead in tokens
private let toolDefinitionOverheadTokens = 8

/// Tool output overhead in tokens
private let toolOutputOverheadTokens = 3

// MARK: - Token Counting Extensions

// MARK: - Private Helpers

private extension Sequence where Element == Transcript.Segment {
  /// Sums the estimated token count across all segments
  var totalEstimatedTokenCount: Int {
    reduce(0) { $0 + $1.estimatedTokenCount }
  }
}

private extension Transcript.Entry {
  /// Returns true if this entry is an instructions entry
  var isInstruction: Bool {
    guard case .instructions = self else { return false }
    return true
  }
}

extension Transcript.Entry {
  /// Estimates the token count for this transcript entry.
  ///
  /// This property calculates tokens based on the entry type:
  /// - Instructions, prompts, and responses: Sum of all segment tokens
  /// - Tool calls: Tool name + arguments + overhead (5 tokens)
  /// - Tool output: Sum of segments + overhead (3 tokens)
  ///
  /// Uses the package's empirically calibrated estimate.
  public var estimatedTokenCount: Int {
    switch self {
    case .instructions(let instructions):
      let definitionTokens = instructions.toolDefinitions.reduce(0) { total, definition in
        total + estimateTokensConservative(from: definition.name) +
        estimateTokensConservative(from: definition.description) +
        toolDefinitionOverheadTokens
      }
      return instructions.segments.totalEstimatedTokenCount + definitionTokens

    case .prompt(let prompt):
      return prompt.segments.totalEstimatedTokenCount

    case .response(let response):
      return response.segments.totalEstimatedTokenCount

    case .toolCalls(let toolCalls):
      return toolCalls.reduce(0) { total, call in
        total + estimateTokens(from: call.toolName) +
        estimateTokens(from: call.arguments) + toolCallOverheadTokens
      }

    case .toolOutput(let output):
      return output.segments.totalEstimatedTokenCount + toolOutputOverheadTokens

    #if compiler(>=6.4)
    case .reasoning(let reasoning):
      return reasoning.segments.totalEstimatedTokenCount + toolOutputOverheadTokens
    #endif

    @unknown default:
      // Return 0 for unknown entry types to avoid crashes
      return 0
    }
  }
}

extension Transcript.Segment {
  /// Estimates the token count for this transcript segment.
  ///
  /// Calculates tokens based on segment type:
  /// - Text segments: Character count divided by the calibrated ratio
  /// - Structured segments: JSON representation length divided by the calibrated ratio
  ///
  /// Uses the package's calibrated estimate.
  public var estimatedTokenCount: Int {
    switch self {
    case .text(let textSegment):
      return estimateTokens(from: textSegment.content)

    case .structure(let structuredSegment):
      return estimateTokens(from: structuredSegment.content)

    #if compiler(>=6.4)
    case .attachment(let attachmentSegment):
      return estimateTokens(from: attachmentSegment.label ?? "image attachment") + 12

    case .custom(let customSegment):
      return estimateTokens(from: customSegment.description)
    #endif

    @unknown default:
      // Return 0 for unknown segment types to avoid crashes
      return 0
    }
  }
}

extension Transcript {
  /// Estimates the total token count for all entries in this transcript.
  ///
  /// Returns the sum of estimated tokens across all transcript entries.
  /// Uses the package's calibrated estimate.
  ///
  /// Example:
  /// ```swift
  /// let transcript = Transcript(...)
  /// let tokens = transcript.estimatedTokenCount
  /// print("Transcript uses approximately \(tokens) tokens")
  /// ```
  public var estimatedTokenCount: Int {
    return self.reduce(0) { $0 + $1.estimatedTokenCount }
  }

  /// Returns the estimated token count with a safety buffer.
  ///
  /// Adds a 25% buffer plus 100 tokens for system overhead to the base estimate.
  /// Use this for conservative token budgeting to avoid hitting context limits.
  ///
  /// Example:
  /// ```swift
  /// let transcript = Transcript(...)
  /// let safeTokens = transcript.safeEstimatedTokenCount
  /// if safeTokens < 4000 {
  ///     // Safe to continue conversation
  /// }
  /// ```
  public var safeEstimatedTokenCount: Int {
    let baseTokens = estimatedTokenCount
    let buffer = Int(Double(baseTokens) * safetyBufferMultiplier)
    let systemOverhead = systemOverheadTokens

    return baseTokens + buffer + systemOverhead
  }

  /// Checks if the transcript is approaching the token limit.
  ///
  /// - Parameters:
  ///   - threshold: The percentage of maxTokens at which to trigger (default: 0.70 or 70%)
  ///   - maxTokens: The maximum token limit for the model (default: 4096)
  ///
  /// - Returns: `true` if the safe estimated token count exceeds the threshold
  ///
  /// Example:
  /// ```swift
  /// let transcript = Transcript(...)
  /// if transcript.isApproachingLimit(threshold: 0.8, maxTokens: 4096) {
  ///     // Trim transcript or summarize conversation
  /// }
  /// ```
  public func isApproachingLimit(threshold: Double = 0.70, maxTokens: Int = 4096) -> Bool {
    let currentTokens = safeEstimatedTokenCount
    let limitThreshold = Int(Double(maxTokens) * threshold)
    return currentTokens > limitThreshold
  }

  /// Returns a subset of entries that fit within the specified token budget.
  ///
  /// This method implements a sliding window approach:
  /// 1. Includes the first instructions entry (if present and it fits within the budget)
  /// 2. Adds the most recent entries that fit within the budget
  /// 3. Preserves conversation recency while respecting token limits
  ///
  /// - Parameter budget: The maximum number of tokens allowed
  /// - Returns: An array of entries that fit within the budget
  /// - Important: The first instructions entry is always preserved. When it
  ///   alone exceeds the budget, the result contains only that entry.
  ///
  /// Example:
  /// ```swift
  /// let transcript = Transcript(...)
  /// let trimmed = transcript.entriesWithinTokenBudget(2000)
  /// let newTranscript = Transcript(entries: trimmed)
  /// ```
  public func entriesWithinTokenBudget(_ budget: Int) -> [Transcript.Entry] {
    foundationModelsKitEstimatedEntriesWithinTokenBudget(budget)
  }

  func foundationModelsKitEstimatedEntriesWithinTokenBudget(
    _ budget: Int
  ) -> [Transcript.Entry] {
    let contentBudget = estimatedContentBudget(forSafeBudget: budget)
    let firstInstruction = self.first(where: \.isInstruction)
    let instructionTokens = firstInstruction?.estimatedTokenCount ?? 0

    if let firstInstruction, instructionTokens > contentBudget {
      return [firstInstruction]
    }

    var tokenCount = instructionTokens
    var recentEntriesToKeep: [Transcript.Entry] = []

    // Iterate backwards through non-instructions and collect what fits in the remaining budget.
    for entry in self.reversed() {
      if entry.isInstruction { continue }

      let entryTokens = entry.estimatedTokenCount
      guard tokenCount + entryTokens <= contentBudget else { break }
      tokenCount += entryTokens
      recentEntriesToKeep.append(entry)
    }

    // Preserve instructions even when they alone exceed the requested budget.
    var result = firstInstruction.map { [$0] } ?? []
    result.append(contentsOf: recentEntriesToKeep.reversed())
    return result
  }
}

private func estimatedContentBudget(forSafeBudget budget: Int) -> Int {
  guard budget > systemOverheadTokens else { return 0 }
  return Int(
    floor(
      Double(budget - systemOverheadTokens) / (1 + safetyBufferMultiplier)
    )
  )
}

// MARK: - Token Estimation Utilities

/// Estimates token count from a string using empirically calibrated ratio: 4.75 characters per token.
///
/// Uses balanced calibration based on xctrace Foundation Models instrument measurements.
/// For conservative estimates, use `estimateTokensConservative(from:)`.
///
/// - Parameter text: The text to estimate tokens for
/// - Returns: Estimated token count (minimum 1 for non-empty strings)
///
/// - Note: Actual tokens may vary by ±16% depending on content.
///
/// Example:
/// ```swift
/// let tokens = estimateTokens(from: "Hello, world!")
/// print("Token count: \(tokens)")  // Prints approximately 3
/// ```
public func estimateTokens(from text: String) -> Int {
  guard !text.isEmpty else { return 0 }

  let characterCount = text.count
  let tokensPerChar = 1.0 / charactersPerToken

  return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

/// Estimates token count using Apple's conservative guidance: 4.5 characters per token.
///
/// This overestimates by ~5-10% but ensures you won't exceed context limits.
/// Recommended for critical token budget management.
///
/// - Parameter text: The text to estimate tokens for
/// - Returns: Conservatively estimated token count
///
/// Example:
/// ```swift
/// let tokens = estimateTokensConservative(from: systemPrompt)
/// if tokens < 3000 {
///     // Safe to proceed
/// }
/// ```
public func estimateTokensConservative(from text: String) -> Int {
  guard !text.isEmpty else { return 0 }

  let characterCount = text.count
  let tokensPerChar = 1.0 / conservativeCharactersPerToken

  return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}

/// Estimates token count from structured content (GeneratedContent) by converting to JSON.
///
/// - Parameter content: The GeneratedContent to estimate tokens for
/// - Returns: Estimated token count based on JSON representation length
///
/// Example:
/// ```swift
/// let content = GeneratedContent(...)
/// let tokens = estimateTokens(from: content)
/// ```
public func estimateTokens(from content: GeneratedContent) -> Int {
  let jsonString = content.jsonString
  let characterCount = jsonString.count
  let tokensPerChar = 1.0 / charactersPerToken

  return max(1, Int(ceil(Double(characterCount) * tokensPerChar)))
}
