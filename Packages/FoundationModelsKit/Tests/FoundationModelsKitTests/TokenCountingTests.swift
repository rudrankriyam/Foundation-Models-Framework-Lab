//
//  TokenCountingTests.swift
//  FoundationModelsKitTests
//
//  Tests for token counting and context window management utilities.
//

import Foundation
import FoundationModels
import Testing
@testable import FoundationModelsKit

@Suite("Token Counting Tests")
struct TokenCountingTests {

  // MARK: - estimateTokens(from:) Tests

  @Test("Empty string returns zero tokens")
  func emptyStringReturnsZero() {
    let tokens = estimateTokens(from: "")
    #expect(tokens == 0)
  }

  @Test("Single character returns at least one token")
  func singleCharacterReturnsOne() {
    let tokens = estimateTokens(from: "a")
    #expect(tokens >= 1)
  }

  @Test("Short text returns expected token count")
  func shortTextTokenCount() {
    // "Hello, world!" is 13 characters
    // At 4.75 chars/token, should be ~3 tokens
    let tokens = estimateTokens(from: "Hello, world!")
    #expect(tokens >= 2 && tokens <= 4)
  }

  @Test("Longer text scales appropriately")
  func longerTextScales() {
    let shortText = "Hello"
    let longText = String(repeating: "Hello ", count: 100)

    let shortTokens = estimateTokens(from: shortText)
    let longTokens = estimateTokens(from: longText)

    #expect(longTokens > shortTokens * 50)
  }

  // MARK: - estimateTokensConservative(from:) Tests

  @Test("Conservative estimate is higher than standard estimate")
  func conservativeEstimateIsHigher() {
    let text = "This is a sample text for testing token estimation."
    let standard = estimateTokens(from: text)
    let conservative = estimateTokensConservative(from: text)

    #expect(conservative >= standard)
  }

  @Test("Conservative empty string returns zero")
  func conservativeEmptyStringReturnsZero() {
    let tokens = estimateTokensConservative(from: "")
    #expect(tokens == 0)
  }

  @Test("Estimated token window stays within the safe budget")
  func estimatedTokenWindowStaysWithinSafeBudget() {
    let entries: [Transcript.Entry] = (1...4).map { index in
      .prompt(.foundationModelsTools("\(index) " + String(repeating: "a", count: 188)))
    }
    let transcript = Transcript(entries: entries)

    let trimmed = transcript.entriesWithinTokenBudget(220)
    let trimmedTranscript = Transcript(entries: trimmed)

    #expect(trimmed.count < entries.count)
    #expect(trimmedTranscript.safeEstimatedTokenCount <= 220)
  }

  @Test("Token window preserves oversized instructions")
  func tokenWindowPreservesOversizedInstructions() {
    let instruction: Transcript.Entry = .instructions(
      .foundationModelsTools(String(repeating: "system ", count: 200))
    )
    let transcript = Transcript(entries: [
      instruction,
      .prompt(.foundationModelsTools("Latest user prompt"))
    ])

    let trimmed = transcript.entriesWithinTokenBudget(120)

    #expect(trimmed == [instruction])
  }

  @Test("Instruction estimates include tool definitions")
  func instructionEstimatesIncludeToolDefinitions() throws {
    let schema = try GenerationSchema(
      root: DynamicGenerationSchema(
        name: "WeatherArguments",
        properties: [
          .init(name: "city", schema: .init(type: String.self))
        ]
      ),
      dependencies: []
    )
    let segments: [Transcript.Segment] = [
      .text(Transcript.TextSegment(content: "Use tools when helpful."))
    ]
    let textOnly: Transcript.Entry = .instructions(
      Transcript.Instructions(segments: segments, toolDefinitions: [])
    )
    let withTool: Transcript.Entry = .instructions(
      Transcript.Instructions(
        segments: segments,
        toolDefinitions: [
          Transcript.ToolDefinition(
            name: "weather",
            description: "Looks up current weather for a city.",
            parameters: schema
          )
        ]
      )
    )

    #expect(withTool.estimatedTokenCount > textOnly.estimatedTokenCount)
    #expect(
      withTool.estimatedTokenCount - textOnly.estimatedTokenCount >=
      estimateTokensConservative(from: "weatherLooks up current weather for a city.")
    )
  }
}

@Suite("Token Estimation Accuracy Tests")
struct TokenEstimationAccuracyTests {

  @Test("Token estimation is consistent")
  func tokenEstimationIsConsistent() {
    let text = "The quick brown fox jumps over the lazy dog."

    let tokens1 = estimateTokens(from: text)
    let tokens2 = estimateTokens(from: text)

    #expect(tokens1 == tokens2)
  }

  @Test("Whitespace is counted in tokens")
  func whitespaceIsCounted() {
    let noSpaces = "HelloWorld"
    let withSpaces = "Hello World"

    let noSpaceTokens = estimateTokens(from: noSpaces)
    let withSpaceTokens = estimateTokens(from: withSpaces)

    // With spaces should have slightly more tokens due to extra character
    #expect(withSpaceTokens >= noSpaceTokens)
  }

  @Test("Special characters are handled")
  func specialCharactersHandled() {
    let text = "Hello! @#$%^&*() World"
    let tokens = estimateTokens(from: text)

    #expect(tokens > 0)
  }

  @Test("Unicode characters are handled")
  func unicodeCharactersHandled() {
    let text = "你好, world! 👋" // This string contains CJK characters and emoji.
    let tokens = estimateTokens(from: text)
    // The string has 12 characters (grapheme clusters). Expected tokens: ceil(12 / 4.75) = 3
    #expect(tokens >= 2 && tokens <= 4)
  }

  @Test("Newlines are handled")
  func newlinesHandled() {
    let text = "Line 1\nLine 2\nLine 3"
    let tokens = estimateTokens(from: text)

    #expect(tokens > 0)
  }
}

@Suite("Transcript History Transform Tests")
struct TranscriptHistoryTransformTests {

  @Test("Rolling window keeps the most recent entries")
  func rollingWindowKeepsMostRecentEntries() {
    let entries: [Transcript.Entry] = [
      .instructions(.foundationModelsTools("System")),
      .prompt(.foundationModelsTools("First")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer")),
      .prompt(.foundationModelsTools("Second")),
      .toolOutput(.foundationModelsTools(id: "second-output", text: "Second answer"))
    ]

    let window = entries.rollingWindow(entries: 3)

    #expect(window.count == 3)
    #expect(window.map { $0.foundationModelsToolsText } == [
      "First answer",
      "Second",
      "Second answer"
    ])
  }

  @Test("Rolling window returns empty array for non-positive sizes")
  func rollingWindowReturnsEmptyForNonPositiveSizes() {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer"))
    ]

    #expect(entries.rollingWindow(entries: 0).isEmpty)
    #expect(entries.rollingWindow(entries: -1).isEmpty)
  }

  @Test("Rolling window can split an entry pair")
  func rollingWindowCanSplitEntryPair() {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer")),
      .prompt(.foundationModelsTools("Second"))
    ]

    let window = entries.rollingWindow(entries: 2)

    #expect(window.map { $0.foundationModelsToolsText } == [
      "First answer",
      "Second"
    ])
  }

  @Test("Dropping completed tool calls removes exchanges before the latest prompt")
  func droppingCompletedToolCallsRemovesExchangesBeforeLatestPrompt() {
    let oldToolCalls = Transcript.ToolCalls(id: "old-calls", [])
    let oldToolOutput = Transcript.ToolOutput(
      id: "old-output",
      toolName: "search",
      segments: [.text(Transcript.TextSegment(content: "Old search output"))]
    )
    let latestToolCalls = Transcript.ToolCalls(id: "latest-calls", [])
    let latestToolOutput = Transcript.ToolOutput(
      id: "latest-output",
      toolName: "lookup",
      segments: [.text(Transcript.TextSegment(content: "Latest lookup output"))]
    )

    let entries: [Transcript.Entry] = [
      .instructions(.foundationModelsTools("System")),
      .prompt(.foundationModelsTools("First")),
      .toolCalls(oldToolCalls),
      .toolOutput(oldToolOutput),
      .prompt(.foundationModelsTools("Second")),
      .toolCalls(latestToolCalls),
      .toolOutput(latestToolOutput),
      .prompt(.foundationModelsTools("Continue"))
    ]

    let transformed = entries.droppingCompletedToolCalls()

    #expect(transformed.map { $0.foundationModelsToolsKind } == [
      "instructions",
      "prompt",
      "prompt",
      "prompt"
    ])
    #expect(transformed.contains { entry in
      if case .toolOutput(let output) = entry {
        return output.id == "old-output"
      }
      return false
    } == false)
    #expect(transformed.contains { entry in
      if case .toolCalls(let calls) = entry {
        return calls.id == "latest-calls"
      }
      return false
    } == false)
  }

  @Test("Dropping completed tool calls keeps current tool exchange")
  func droppingCompletedToolCallsKeepsCurrentToolExchange() {
    let toolCalls = Transcript.ToolCalls(id: "current-calls", [])
    let toolOutput = Transcript.ToolOutput(
      id: "current-output",
      toolName: "search",
      segments: [.text(Transcript.TextSegment(content: "Current search output"))]
    )

    let entries: [Transcript.Entry] = [
      .instructions(.foundationModelsTools("System")),
      .prompt(.foundationModelsTools("First")),
      .toolCalls(toolCalls),
      .toolOutput(toolOutput)
    ]

    let transformed = entries.droppingCompletedToolCalls()

    #expect(transformed.map { $0.foundationModelsToolsKind } == [
      "instructions",
      "prompt",
      "toolCalls",
      "toolOutput"
    ])
    #expect(transformed.contains { entry in
      if case .toolOutput(let output) = entry {
        return output.id == "current-output"
      }
      return false
    })
  }

  @Test("Dropping completed tool calls preserves transcript with no outputs")
  func droppingCompletedToolCallsPreservesTranscriptWithNoOutputs() {
    let entries: [Transcript.Entry] = [
      .instructions(.foundationModelsTools("System")),
      .prompt(.foundationModelsTools("First")),
      .prompt(.foundationModelsTools("Second"))
    ]

    let transformed = entries.droppingCompletedToolCalls()

    #expect(transformed.map { $0.foundationModelsToolsText } == [
      "System",
      "First",
      "Second"
    ])
  }

  @Test("Summarizing history preserves entries when under threshold")
  func summarizingHistoryPreservesEntriesWhenUnderThreshold() async throws {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer"))
    ]

    let summarized = await entries.summarizingHistory(entryThreshold: 10) { _ in
      Issue.record("Summarizer should not be called under threshold")
      return "Unused"
    }

    #expect(summarized == entries)
  }

  @Test("Summarizing history preserves entries when latest entry is not a prompt")
  func summarizingHistoryPreservesEntriesWhenLatestEntryIsNotPrompt() async throws {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer"))
    ]

    let summarized = await entries.summarizingHistory(entryThreshold: 1) { _ in
      Issue.record("Summarizer should not be called unless the latest entry is a prompt")
      return "Unused"
    }

    #expect(summarized == entries)
  }

  @Test("Summarizing history collapses prior entries into latest prompt")
  func summarizingHistoryCollapsesPriorEntriesIntoLatestPrompt() async throws {
    let entries: [Transcript.Entry] = [
      .instructions(.foundationModelsTools("System")),
      .prompt(.foundationModelsTools("First topic.")),
      .toolOutput(.foundationModelsTools(id: "first-output", text: "First answer.")),
      .prompt(.foundationModelsTools("Second topic."))
    ]

    var receivedPrompt = ""
    let summarized = await entries.summarizingHistory(entryThreshold: 2) { prompt in
      receivedPrompt = prompt
      return "User asked about the first topic."
    }

    #expect(receivedPrompt == """
      Summarize this conversation:

      User: First topic.
      Tool output (testTool): First answer.
      User: Second topic.
      """)
    #expect(summarized.count == 2)
    #expect(summarized.map { $0.foundationModelsToolsKind } == [
      "instructions",
      "prompt"
    ])
    let expectedPostamble =
      "Do not begin with phrases like \"Based on the context\", \"Based on the facts\", " +
      "\"Based on the summary\", or any reference to a summary or the facts provided. " +
      "Treat the summary and facts above as things you naturally remember."
    #expect(summarized.last?.foundationModelsToolsText == """
      Summary of the conversation so far:
      User asked about the first topic.

      \(expectedPostamble)

      Second topic.
      """)
  }

  @Test("Summarizing history preserves instruction tool definitions")
  func summarizingHistoryPreservesInstructionToolDefinitions() async throws {
    let toolDefinition = Transcript.ToolDefinition(
      name: "search",
      description: "Searches documents",
      parameters: GenerationSchema(type: String.self, properties: [])
    )
    let instructions = Transcript.Instructions(
      segments: [.text(Transcript.TextSegment(content: "Use tools carefully."))],
      toolDefinitions: [toolDefinition]
    )
    let entries: [Transcript.Entry] = [
      .instructions(instructions),
      .prompt(.foundationModelsTools("First topic.")),
      .prompt(.foundationModelsTools("Second topic."))
    ]

    let summarized = await entries.summarizingHistory(entryThreshold: 1) { _ in
      "The user is discussing two topics."
    }

    guard case .instructions(let preservedInstructions) = summarized.first else {
      Issue.record("Expected summarized history to preserve instructions")
      return
    }

    #expect(preservedInstructions == instructions)
    #expect(preservedInstructions.toolDefinitions == [toolDefinition])
  }

  @Test("Summarizing history uses custom postamble")
  func summarizingHistoryUsesCustomPostamble() async throws {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First topic.")),
      .prompt(.foundationModelsTools("Second topic."))
    ]

    let summarized = await entries.summarizingHistory(
      entryThreshold: 1,
      summaryPostamble: "Continue naturally."
    ) { _ in
      "The user is discussing two topics."
    }

    #expect(summarized.first?.foundationModelsToolsText == """
      Summary of the conversation so far:
      The user is discussing two topics.

      Continue naturally.

      Second topic.
      """)
  }

  @Test("Summarizing history omits empty postamble")
  func summarizingHistoryOmitsEmptyPostamble() async throws {
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First topic.")),
      .prompt(.foundationModelsTools("Second topic."))
    ]

    let summarized = await entries.summarizingHistory(
      entryThreshold: 1,
      summaryPostamble: ""
    ) { _ in
      "The user is discussing two topics."
    }

    #expect(summarized.first?.foundationModelsToolsText == """
      Summary of the conversation so far:
      The user is discussing two topics.

      Second topic.
      """)
  }

  @Test("Summarizing history preserves latest prompt options and response format")
  func summarizingHistoryPreservesLatestPromptOptionsAndResponseFormat() async throws {
    let responseFormat = Transcript.ResponseFormat(
      schema: GenerationSchema(type: String.self, properties: [])
    )
    let latestPrompt = Transcript.Prompt(
      segments: [.text(Transcript.TextSegment(content: "Second topic."))],
      options: GenerationOptions(temperature: 0.3),
      responseFormat: responseFormat
    )
    let entries: [Transcript.Entry] = [
      .prompt(.foundationModelsTools("First topic.")),
      .prompt(latestPrompt)
    ]

    let summarized = await entries.summarizingHistory(entryThreshold: 1) { _ in
      "The user is discussing two topics."
    }

    guard case .prompt(let prompt) = summarized.first else {
      Issue.record("Expected summarized history to contain a prompt")
      return
    }

    #expect(prompt.options == latestPrompt.options)
    #expect(prompt.responseFormat == latestPrompt.responseFormat)
  }
}

private extension Transcript.Entry {
  var foundationModelsToolsKind: String {
    if case .instructions = self { return "instructions" }
    if case .prompt = self { return "prompt" }
    if case .toolCalls = self { return "toolCalls" }
    if case .toolOutput = self { return "toolOutput" }
    if case .response = self { return "response" }
    return "unknown"
  }

  var foundationModelsToolsText: String {
    if case .instructions(let instructions) = self {
      return instructions.segments.foundationModelsToolsText
    }
    if case .prompt(let prompt) = self {
      return prompt.segments.foundationModelsToolsText
    }
    if case .toolOutput(let output) = self {
      return output.segments.foundationModelsToolsText
    }
    if case .response(let response) = self {
      return response.segments.foundationModelsToolsText
    }
    if case .toolCalls(let calls) = self {
      return calls.id
    }
    return ""
  }
}

private extension [Transcript.Segment] {
  var foundationModelsToolsText: String {
    compactMap { segment in
      if case .text(let text) = segment {
        return text.content
      }
      return nil
    }.joined()
  }
}

private extension Transcript.Instructions {
  static func foundationModelsTools(_ text: String) -> Self {
    Self(
      segments: [.text(Transcript.TextSegment(content: text))],
      toolDefinitions: []
    )
  }
}

private extension Transcript.Prompt {
  static func foundationModelsTools(_ text: String) -> Self {
    Self(segments: [.text(Transcript.TextSegment(content: text))])
  }
}

private extension Transcript.ToolOutput {
  static func foundationModelsTools(id: String, text: String) -> Self {
    Self(
      id: id,
      toolName: "testTool",
      segments: [.text(Transcript.TextSegment(content: text))]
    )
  }
}
