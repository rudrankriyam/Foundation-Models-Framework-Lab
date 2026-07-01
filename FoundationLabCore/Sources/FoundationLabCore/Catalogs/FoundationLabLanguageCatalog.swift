import Foundation
import FoundationModelsKit

public struct LanguagePrompt: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let language: String
    public let flag: String
    public let text: String

    public init(
        id: UUID = UUID(),
        language: String,
        flag: String,
        text: String
    ) {
        self.id = id
        self.language = language
        self.flag = flag
        self.text = text
    }
}

public struct LanguageConversationStep: Sendable, Hashable, Codable, Identifiable {
    public let id: UUID
    public let label: String
    public let prompt: String

    public init(
        id: UUID = UUID(),
        label: String,
        prompt: String
    ) {
        self.id = id
        self.label = label
        self.prompt = prompt
    }
}

public enum FoundationLabLanguageCatalog {
    public static let multilingualSystemPrompt = """
    You are a multilingual assistant who can naturally switch between languages and maintain conversational context.
    """

    public static let defaultConversationSteps: [LanguageConversationStep] = [
        .init(label: "English", prompt: "Hello, how are you?"),
        .init(label: "Spanish", prompt: "Hola, ¿cómo estás?"),
        .init(label: "English", prompt: "Now answer in English please"),
        .init(label: "Memory", prompt: "What language did I first speak to you in?"),
        .init(label: "Switch", prompt: "Please respond in French from now on"),
        .init(label: "French", prompt: "Comment allez-vous aujourd'hui?"),
        .init(label: "Mixed", prompt: "Can you parler both English and French in your response?")
    ]

    public static let multilingualPromptTemplates: [String: String] = [
        "en": "What is the capital of France? Please provide a brief answer.",
        "es": "¿Cuál es la capital de España? Por favor, proporciona una respuesta breve.",
        "fr": "Quelle est la capitale de l'Allemagne ? Veuillez donner une réponse brève.",
        "de": "Was ist die Hauptstadt von Italien? Bitte geben Sie eine kurze Antwort.",
        "it": "Qual è la capitale del Portogallo? Per favore, fornisci una risposta breve.",
        "pt": "Qual é a capital do Brasil? Por favor, forneça uma resposta breve.",
        "zh": "中国的首都是什么？请简要回答。",
        "ja": "日本の首都は何ですか？簡潔にお答えください。",
        "ko": "한국의 수도는 어디인가요? 간단히 답해주세요."
    ]

    public static func multilingualPrompts(
        using supportedLanguages: [FoundationModelSupportedLanguage],
        locale: Locale = .current,
        limit: Int? = nil
    ) -> [LanguagePrompt] {
        var prompts: [LanguagePrompt] = []

        for language in supportedLanguages {
            guard let promptText = multilingualPromptTemplates[language.languageCode] else {
                continue
            }

            prompts.append(
                LanguagePrompt(
                    language: language.displayName(in: locale),
                    flag: "🌐",
                    text: promptText
                )
            )
        }

        if prompts.isEmpty {
            prompts = [
                LanguagePrompt(
                    language: "English",
                    flag: "🌐",
                    text: multilingualPromptTemplates["en"] ?? "What is the capital of France?"
                )
            ]
        }

        if let limit, limit > 0 {
            return Array(prompts.prefix(limit))
        }

        return prompts
    }
}
