//
//  DefaultPrompts.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import Foundation

/// Default prompts for each example type
enum DefaultPrompts {

  // MARK: - Basic Examples

  static let basicChat = "Suggest a catchy name for a new coffee shop."

  static let basicChatSuggestions = [
    "Tell me a joke about programming",
    "Explain quantum computing in simple terms",
    "What are the benefits of meditation?",
    "Write a haiku about artificial intelligence",
    "Give me 5 creative pizza topping combinations"
  ]

  // MARK: - Structured Data

  static let structuredData = "Suggest a sci-fi book."

  static let structuredDataSuggestions = [
    "Recommend a mystery novel",
    "Suggest a fantasy book for beginners",
    "What's a good historical fiction book?",
    "Recommend a book about space exploration",
    "Suggest a classic literature book"
  ]

  // MARK: - Generation Guides

  static let generationGuides = "Write a product review for a smartphone."

  static let generationGuidesSuggestions = [
    "Review a laptop for students",
    "Write a review for wireless headphones",
    "Review a fitness tracker",
    "Write a review for a coffee maker",
    "Review a streaming service"
  ]

  // MARK: - Streaming

  static let streaming = "Write a sonnet about nature"

  static let streamingSuggestions = [
    "Write a short poem about technology",
    "Create a limerick about coding",
    "Write a haiku about the changing seasons.",
    "Compose a haiku about morning coffee",
    "Write a free verse poem about dreams"
  ]

  // MARK: - Journaling

  static let journaling = """
  Mood: A bit anxious and overwhelmed by deadlines.
  Sleep: Restless, woke up twice.
  Quote: "Enjoy when you can, and endure when you must."
  Entry: I tried to focus today but kept jumping between tasks and felt guilty about not finishing. I want a calmer rhythm tomorrow.
  """

  static let journalingSuggestions = [
    """
    Mood: Grateful but tired.
    Sleep: Light, not fully rested.
    Quote: "Small steps every day."
    Entry: I had a good day with family, but I'm feeling low energy and want to slow down this week.
    """,
    """
    Mood: Restless and distracted.
    Sleep: Late night, low quality.
    Affirmation: "I can focus on one thing at a time."
    Entry: My mind kept drifting. I want to feel more present and finish what I start.
    """,
    """
    Mood: Hopeful but unsure.
    Sleep: Fine.
    Quote: "Courage grows in uncertainty."
    Entry: I'm excited about a new project, yet I'm worried about getting it right.
    """,
    """
    Mood: Calm and reflective.
    Sleep: Deep and steady.
    Quote: "Let the day unfold without rushing it."
    Entry: I enjoyed a quiet morning and want to keep this sense of balance.
    """,
    """
    Mood: Stressed and tense.
    Sleep: Fragmented.
    Affirmation: "I can handle what's in front of me."
    Entry: Deadlines are piling up and I need a kinder way to handle the pressure.
    """
  ]

  // MARK: - Creative Writing

  static let creativeWriting = "Write a story outline about time travel."

  static let creativeWritingSuggestions = [
    "Create a mystery story outline",
    "Write a sci-fi story concept",
    "Outline a romantic comedy plot",
    "Create a thriller story outline",
    "Write a fantasy adventure concept"
  ]

  // MARK: - Model Availability

  static let modelAvailability = "Check if Apple Intelligence is available on this device."

  // MARK: - Instructions

  static let basicChatInstructions =
    "You are a helpful and creative assistant. Provide clear, concise, and engaging responses."

  static let creativeWritingInstructions =
    "You are a creative writing assistant. Help users develop compelling stories, characters, and narratives."

  static let journalingInstructions =
    """
    You are a gentle journaling coach. Offer empathetic prompts, a short uplifting message,
    2-3 sentence starters, 3 summary bullets, and a few themes without judgment.
    """

  // Model Availability
  static let modelAvailabilitySuggestions = [
    "Check if Apple Intelligence is available",
    "Show me the current model status",
    "What model capabilities are enabled?"
  ]
}

// MARK: - Dynamic Code Examples

extension DefaultPrompts {
  private static func codeEscaped(_ value: String) -> String {
    value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
      .replacingOccurrences(of: "\r\n", with: "\\n")
      .replacingOccurrences(of: "\n", with: "\\n")
      .replacingOccurrences(of: "\r", with: "\\n")
  }

  static func basicChatCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    let escapedPrompt = codeEscaped(prompt)

    if let instructions = instructions, !instructions.isEmpty {
      let escapedInstructions = codeEscaped(instructions)
      code += "// Create a session with custom instructions\n"
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(escapedInstructions)\")\n"
      code += ")\n"
    } else {
      code += "// Create a basic language model session\n"
      code += "let session = LanguageModelSession()\n"
    }

    code += "\n// Generate a response\n"
    code += "let response = try await session.respond(to: \"\(escapedPrompt)\")\n"
    code += "print(response.content)"

    return code
  }

  static func structuredDataCode(prompt: String) -> String {
    let escapedPrompt = codeEscaped(prompt)
    return """
import FoundationLabCore

let useCase = GenerateBookRecommendationUseCase()
let response = try await useCase.execute(
    GenerateBookRecommendationRequest(
        prompt: "\(escapedPrompt)",
        context: FoundationModelInvocationContext(source: .app)
    )
)
let book = response.recommendation

"""
  }

  static func generationGuidesCode(prompt: String) -> String {
    let escapedPrompt = codeEscaped(prompt)
    return """
import FoundationModels
import FoundationModelsKit

// Uses ProductReview struct from DataModels.swift
let session = LanguageModelSession()
let response = try await session.respond(
    to: "\(escapedPrompt)",
    generating: ProductReview.self
)
let review = response.content

"""
  }

  static func streamingResponseCode(prompt: String) -> String {
    let escapedPrompt = codeEscaped(prompt)
    return """
import FoundationModels

let session = LanguageModelSession()

// Stream the response token by token
let stream = session.streamResponse(to: "\(escapedPrompt)")
for try await partialResponse in stream {
}
"""
  }

  static func journalingCode(prompt: String) -> String {
    let escapedPrompt = codeEscaped(prompt)
    return """
import FoundationModels

// Uses JournalEntrySummary struct from DataModels.swift
let session = LanguageModelSession(
    instructions: Instructions("\(journalingInstructions)")
)
let response = try await session.respond(
    to: "\(escapedPrompt)",
    generating: JournalEntrySummary.self
)
let summary = response.content

"""
  }

  static func creativeWritingCode(prompt: String, instructions: String? = nil) -> String {
    var code = "import FoundationModels\n\n"
    code += "// Uses StoryOutline struct from DataModels.swift\n"
    let escapedPrompt = codeEscaped(prompt)

    if let instructions = instructions, !instructions.isEmpty {
      let escapedInstructions = codeEscaped(instructions)
      code += "// Create session with creative writing instructions\n"
      code += "let session = LanguageModelSession(\n"
      code += "    instructions: Instructions(\"\(escapedInstructions)\")\n"
      code += ")\n\n"
    } else {
      code += "let session = LanguageModelSession()\n\n"
    }

    code += "let response = try await session.respond(\n"
    code += "    to: \"\(escapedPrompt)\",\n"
    code += "    generating: StoryOutline.self\n"
    code += ")\n\n"
    code += "let story = response.content\n"
    code += "print(\"Title: \\(story.title)\")\n"
    code += "print(\"Genre: \\(story.genre)\")\n"
    code += "print(\"Themes: \\(story.themes.joined(separator: \", \"))\")"

    return code
  }

  static let modelAvailabilityCode = """
import FoundationLabCore

let result = FoundationModelAvailabilityUseCase().execute()

if result.isAvailable {
    print("Apple Intelligence is ready")
} else {
    print(result.reason?.rawValue ?? "unknown")
}
"""
}
