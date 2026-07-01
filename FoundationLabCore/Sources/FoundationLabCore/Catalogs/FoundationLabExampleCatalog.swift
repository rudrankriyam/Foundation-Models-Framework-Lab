import Foundation
import FoundationModelsKit

public enum FoundationLabExampleDemo: String, CaseIterable, Sendable, Codable, Identifiable {
    case basicChat = "basic-chat"
    case structuredData = "structured-data"
    case generationGuides = "generation-guides"
    case streaming = "streaming"
    case journaling = "journaling"
    case creativeWriting = "creative-writing"
    case modelAvailability = "model-availability"
    case generationOptions = "generation-options"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .basicChat:
            return "One-shot"
        case .structuredData:
            return "Structured Data"
        case .generationGuides:
            return "Generation Guides"
        case .streaming:
            return "Streaming Response"
        case .journaling:
            return "Journaling"
        case .creativeWriting:
            return "Creative Writing"
        case .modelAvailability:
            return "Model Availability"
        case .generationOptions:
            return "Generation Options"
        }
    }

    public var defaultPrompt: String {
        switch self {
        case .basicChat:
            return "Suggest a catchy name for a new coffee shop."
        case .structuredData:
            return "Suggest a sci-fi book."
        case .generationGuides:
            return "Write a product review for a smartphone."
        case .streaming:
            return "Write a sonnet about nature"
        case .journaling:
            return """
            Mood: A bit anxious and overwhelmed by deadlines.
            Sleep: Restless, woke up twice.
            Quote: "Enjoy when you can, and endure when you must."
            Entry: I tried to focus today but kept jumping between tasks and felt guilty about not finishing. \
            I want a calmer rhythm tomorrow.
            """
        case .creativeWriting:
            return "Write a story outline about time travel."
        case .modelAvailability:
            return "Check if Apple Intelligence is available on this device."
        case .generationOptions:
            return "Write a creative story about a magical forest"
        }
    }

    public var suggestions: [String] {
        switch self {
        case .basicChat:
            return [
                "Tell me a joke about programming",
                "Explain quantum computing in simple terms",
                "What are the benefits of meditation?",
                "Write a haiku about artificial intelligence",
                "Give me 5 creative pizza topping combinations"
            ]
        case .structuredData:
            return [
                "Recommend a mystery novel",
                "Suggest a fantasy book for beginners",
                "What's a good historical fiction book?",
                "Recommend a book about space exploration",
                "Suggest a classic literature book"
            ]
        case .generationGuides:
            return [
                "Review a laptop for students",
                "Write a review for wireless headphones",
                "Review a fitness tracker",
                "Write a review for a coffee maker",
                "Review a streaming service"
            ]
        case .streaming:
            return [
                "Write a short poem about technology",
                "Create a limerick about coding",
                "Write a haiku about the changing seasons.",
                "Compose a haiku about morning coffee",
                "Write a free verse poem about dreams"
            ]
        case .journaling:
            return [
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
        case .creativeWriting:
            return [
                "Create a mystery story outline",
                "Write a sci-fi story concept",
                "Outline a romantic comedy plot",
                "Create a thriller story outline",
                "Write a fantasy adventure concept"
            ]
        case .modelAvailability:
            return [
                "Check if Apple Intelligence is available",
                "Show me the current model status",
                "What AI capabilities are enabled?"
            ]
        case .generationOptions:
            return []
        }
    }

    public var defaultSystemPrompt: String? {
        switch self {
        case .basicChat:
            return "You are a helpful and creative assistant. Provide clear, concise, and engaging responses."
        case .journaling:
            return """
            You are a gentle journaling coach. Offer empathetic prompts, a short uplifting message,
            2-3 sentence starters, 3 summary bullets, and a few themes without judgment.
            """
        case .creativeWriting:
            return "You are a creative writing assistant. Help users develop compelling stories, characters, and narratives."
        case .streaming:
            return "You are a creative writer. Generate engaging and vivid content."
        case .structuredData, .generationGuides, .modelAvailability, .generationOptions:
            return nil
        }
    }
}
