import FoundationModels
import Playgrounds
import Foundation

#Playground {
    let languageMapping: [String: String] = [
        "pt": "Portuguese",
        "fr": "French",
        "it": "Italian",
        "de": "German",
        "es": "Spanish",
        "zh": "Chinese (Simplified)",
        "ja": "Japanese",
        "ko": "Korean",
        "en": "English"
    ]

    let userLocale = Locale.autoupdatingCurrent
    let languageCode = userLocale.language.languageCode?.identifier ?? "en"
    let localeIdentifier = userLocale.identifier

    debugPrint("User Locale: \(localeIdentifier)")
    debugPrint("Language Code: \(languageCode)")

    let userLanguage = languageMapping[languageCode] ?? "English"
    debugPrint("Responding in: \(userLanguage)")

    let nutritionSession = LanguageModelSession(instructions: """
        You specialize in nutrition, food analysis, and macro tracking.

        IMPORTANT: Respond in \(userLanguage). All your responses must be in the user's language: \(userLanguage)

        When parsing food descriptions:
        - Estimate realistic portions for typical adults
        - Consider cooking methods (grilled vs fried affects calories)
        - Account for common additions (butter, oil, condiments)
        - Be practical with portion sizes people actually eat
        - Round to reasonable numbers (don't say 247.3 calories, say ~250)

        For nutritional insights:
        - Focus on energy for fitness and performance
        - Be encouraging and supportive like a fitness coach
        - Highlight good nutritional choices
        - Suggest balance when needed
        - Keep responses brief and actionable

        Tone: Supportive, knowledgeable, practical, encouraging.
        Language: \(userLanguage)
        """)

    let testFoods = [
        "I had 2 scrambled eggs with toast",
        "protein shake after workout",
        "pizza slice for lunch",
        "handful of almonds"
    ]

    for food in testFoods {
        do {
            let prompt = """
                RESPOND IN \(userLanguage). Parse this food description into nutritional data: "\(food)"

                Examples of good parsing:
                "I had 2 scrambled eggs with toast" → Consider: 2 large eggs (~140 cal), 1 slice toast (~80 cal), " +
                "cooking butter (~30 cal)"
                "protein shake after workout" → Consider: 1 scoop protein powder (~120 cal) + milk/water
                "pizza slice for lunch" → Consider: 1 slice medium pizza (~280 cal)
                "handful of almonds" → Consider: ~20 almonds (~160 cal)

                Be realistic about portions people actually eat.
                Account for cooking methods and common additions.

                Language: \(userLanguage)
                """

            let response = try await nutritionSession.respond(to: prompt)
            debugPrint("Food: \"\(food)\"")
            debugPrint("Analysis: \(response.content)")

        } catch {
            debugPrint("Error analyzing \"\(food)\": \(error.localizedDescription)")
        }
    }
}
