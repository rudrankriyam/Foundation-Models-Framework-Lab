import Foundation
import FoundationModels
import FoundationModelsKit

public struct FoundationModelsNutritionAnalyzer: NutritionAnalyzing {
    public init() {}

    public func analyzeNutrition(
        for request: AnalyzeNutritionRequest
    ) async throws -> AnalyzeNutritionResult {
        let model = SystemLanguageModel(
            useCase: .general,
            guardrails: (request.guardrails ?? .permissiveContentTransformations).foundationModelsValue
        )
        do {
            let session = LanguageModelSession(
                model: model,
                instructions: Instructions(
                    nutritionInstructions(responseLanguage: request.responseLanguage)
                )
            )

            let parseResponse = try await session.respond(
                to: Prompt(
                    nutritionPrompt(
                        foodDescription: request.foodDescription,
                        responseLanguage: request.responseLanguage
                    )
                ),
                generating: NutritionParsePayload.self
            )

            let insightsResponse = try await session.respond(
                to: Prompt(
                    nutritionInsightsPrompt(
                        parsedNutrition: parseResponse.content,
                        responseLanguage: request.responseLanguage
                    )
                )
            )

            let tokenCount = await session.transcript.tokenCount()

            return AnalyzeNutritionResult(
                analysis: NutritionAnalysis(
                    foodName: parseResponse.content.foodName,
                    calories: parseResponse.content.calories,
                    proteinGrams: parseResponse.content.proteinGrams,
                    carbsGrams: parseResponse.content.carbsGrams,
                    fatGrams: parseResponse.content.fatGrams,
                    insights: insightsResponse.content
                ),
                metadata: FoundationModelExecutionMetadata(
                    provider: "Foundation Models",
                    tokenCount: tokenCount
                )
            )
        } catch {
            guard shouldFallbackNutritionAnalysis(for: error) else {
                throw error
            }

            let fallback = heuristicNutritionAnalysis(
                foodDescription: request.foodDescription,
                responseLanguage: request.responseLanguage
            )

            return AnalyzeNutritionResult(
                analysis: fallback,
                metadata: FoundationModelExecutionMetadata(
                    provider: "Foundation Models (heuristic fallback)",
                    tokenCount: nil
                )
            )
        }
    }
}

private func nutritionInstructions(responseLanguage: String) -> String {
    """
    You estimate meal nutrition facts from short food descriptions.

    IMPORTANT: Respond in \(responseLanguage). All your responses must be in the user's language: \(responseLanguage)

    When parsing food descriptions:
    - Estimate realistic portions for typical adults
    - Consider cooking methods (grilled vs fried affects calories)
    - Account for common additions (butter, oil, condiments)
    - Be practical with portion sizes people actually eat
    - Round to reasonable numbers (don't say 247.3 calories, say ~250)

    For the meal summary:
    - Keep the summary factual and concise
    - Focus on estimated calories and macronutrients
    - Do not provide medical advice or diet coaching
    - Do not recommend what the user should eat next

    Tone: factual, practical, concise.
    Language: \(responseLanguage)
    """
}

private struct NutritionReference {
    let name: String
    let aliases: [String]
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

private struct NutritionSummaryValues {
    let foodName: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
}

private let nutritionReferences: [NutritionReference] = [
    .init(name: "egg", aliases: ["scrambled egg", "scrambled eggs", "egg", "eggs"], calories: 72, protein: 6, carbs: 1, fat: 5),
    .init(name: "toast", aliases: ["toast"], calories: 80, protein: 3, carbs: 15, fat: 1),
    .init(name: "banana", aliases: ["banana", "bananas"], calories: 105, protein: 1, carbs: 27, fat: 0),
    .init(name: "greek yogurt", aliases: ["greek yogurt"], calories: 150, protein: 17, carbs: 8, fat: 4),
    .init(name: "yogurt", aliases: ["yogurt", "curd"], calories: 120, protein: 12, carbs: 9, fat: 3),
    .init(name: "blueberries", aliases: ["blueberries", "blueberry"], calories: 42, protein: 1, carbs: 11, fat: 0),
    .init(name: "almonds", aliases: ["almonds", "almond"], calories: 164, protein: 6, carbs: 6, fat: 14),
    .init(name: "oatmeal", aliases: ["oatmeal", "oats"], calories: 150, protein: 5, carbs: 27, fat: 3),
    .init(name: "pizza slice", aliases: ["pizza slice", "slice of pizza", "pizza"], calories: 285, protein: 12, carbs: 36, fat: 10),
    .init(name: "protein shake", aliases: ["protein shake", "shake"], calories: 180, protein: 25, carbs: 10, fat: 4),
    .init(name: "milk", aliases: ["milk"], calories: 103, protein: 8, carbs: 12, fat: 2),
    .init(name: "chicken", aliases: ["chicken breast", "grilled chicken", "chicken"], calories: 165, protein: 31, carbs: 0, fat: 4),
    .init(name: "rice", aliases: ["rice"], calories: 205, protein: 4, carbs: 45, fat: 0),
    .init(name: "apple", aliases: ["apple", "apples"], calories: 95, protein: 0, carbs: 25, fat: 0)
]

private func shouldFallbackNutritionAnalysis(for error: Error) -> Bool {
    let description = (error as NSError).localizedDescription.lowercased()
    return description.contains("unsafe") || description.contains("sensitive")
}

private func heuristicNutritionAnalysis(
    foodDescription: String,
    responseLanguage: String
) -> NutritionAnalysis {
    let normalizedDescription = foodDescription.lowercased()
    var matchedReferences: [(NutritionReference, Int)] = []

    for reference in nutritionReferences {
        guard let alias = reference.aliases.first(where: { normalizedDescription.contains($0) }) else {
            continue
        }

        matchedReferences.append((reference, inferredQuantity(for: alias, in: normalizedDescription)))
    }

    let matches = matchedReferences.isEmpty
        ? [(NutritionReference(name: foodDescription, aliases: [], calories: 450, protein: 20, carbs: 40, fat: 15), 1)]
        : matchedReferences

    let calories = matches.reduce(0) { $0 + ($1.0.calories * $1.1) }
    let protein = matches.reduce(0) { $0 + ($1.0.protein * $1.1) }
    let carbs = matches.reduce(0) { $0 + ($1.0.carbs * $1.1) }
    let fat = matches.reduce(0) { $0 + ($1.0.fat * $1.1) }

    let foodName = matches.map { reference, quantity in
        quantity > 1 ? "\(quantity)x \(reference.name)" : reference.name
    }
    .joined(separator: ", ")
    let summaryValues = NutritionSummaryValues(
        foodName: foodName,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat
    )

    return NutritionAnalysis(
        foodName: foodName,
        calories: calories,
        proteinGrams: protein,
        carbsGrams: carbs,
        fatGrams: fat,
        insights: localizedNutritionSummary(
            summaryValues,
            responseLanguage: responseLanguage
        )
    )
}

private func inferredQuantity(for alias: String, in description: String) -> Int {
    guard let range = description.range(of: alias) else {
        return 1
    }

    let prefix = description[..<range.lowerBound]
    let trailingToken = prefix.split(whereSeparator: \.isWhitespace).last.map(String.init) ?? ""
    if let quantity = Int(trailingToken), quantity > 0 {
        return quantity
    }

    return 1
}

private func localizedNutritionSummary(
    _ values: NutritionSummaryValues,
    responseLanguage: String
) -> String {
    let language = responseLanguage.lowercased()

    if language.contains("french") {
        return "\(values.foodName) est estime a environ \(values.calories) calories, " +
            "avec \(values.protein) g de proteines, \(values.carbs) g de glucides et \(values.fat) g de lipides. " +
            "Il s'agit d'un resume factuel base sur des portions courantes."
    }
    if language.contains("spanish") {
        return "\(values.foodName) se estima en unas \(values.calories) calorias, " +
            "con \(values.protein) g de proteina, \(values.carbs) g de carbohidratos y \(values.fat) g de grasa. " +
            "Es un resumen factual basado en porciones comunes."
    }
    if language.contains("german") {
        return "\(values.foodName) wird auf etwa \(values.calories) Kalorien mit \(values.protein) g Protein, " +
            "\(values.carbs) g Kohlenhydraten und \(values.fat) g Fett geschatzt. " +
            "Dies ist eine sachliche Schatzung auf Basis ublicher Portionen."
    }
    if language.contains("italian") {
        return "\(values.foodName) e stimato a circa \(values.calories) calorie, " +
            "con \(values.protein) g di proteine, \(values.carbs) g di carboidrati e \(values.fat) g di grassi. " +
            "Si tratta di un riepilogo fattuale basato su porzioni comuni."
    }
    if language.contains("portuguese") {
        return "\(values.foodName) e estimado em cerca de \(values.calories) calorias, " +
            "com \(values.protein) g de proteina, \(values.carbs) g de carboidratos e \(values.fat) g de gordura. " +
            "Este e um resumo factual baseado em porcoes comuns."
    }

    return "\(values.foodName) is estimated at about \(values.calories) calories, " +
        "with \(values.protein)g protein, \(values.carbs)g carbs, and \(values.fat)g fat. " +
        "This is a factual estimate based on common serving sizes."
}

private func nutritionPrompt(
    foodDescription: String,
    responseLanguage: String
) -> String {
    """
    RESPOND IN \(responseLanguage). Parse this food description into nutritional data: "\(foodDescription)"

    Examples of good parsing:
    "I had 2 scrambled eggs with toast" -> Consider: 2 large eggs (~140 cal), 1 slice toast (~80 cal), cooking butter (~30 cal)
    "protein shake after workout" -> Consider: 1 scoop protein powder (~120 cal) + milk/water
    "pizza slice for lunch" -> Consider: 1 slice medium pizza (~280 cal)

    Be realistic about portions people actually eat.
    Account for cooking methods and common additions.

    Language: \(responseLanguage)
    """
}

private func nutritionInsightsPrompt(
    parsedNutrition: NutritionParsePayload,
    responseLanguage: String
) -> String {
    """
    RESPOND IN \(responseLanguage). Provide a brief factual summary of this meal's estimated nutrition:
    \(parsedNutrition.foodName) with \(parsedNutrition.calories) calories,
    \(parsedNutrition.proteinGrams)g protein, \(parsedNutrition.carbsGrams)g carbs,
    \(parsedNutrition.fatGrams)g fat.

    Keep it brief (1-2 sentences).
    Do not provide medical advice, weight-loss advice, or prescriptive recommendations.
    Language: \(responseLanguage)
    """
}

@Generable
private struct NutritionParsePayload: RuntimeCompatibleGenerable {
    @Guide(description: "The name or description of the food item")
    let foodName: String

    @Guide(description: "Estimated calories as a whole number")
    let calories: Int

    @Guide(description: "Protein content in grams as a whole number")
    let proteinGrams: Int

    @Guide(description: "Carbohydrate content in grams as a whole number")
    let carbsGrams: Int

    @Guide(description: "Fat content in grams as a whole number")
    let fatGrams: Int
}
