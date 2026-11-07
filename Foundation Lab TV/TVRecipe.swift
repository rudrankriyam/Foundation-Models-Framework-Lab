//
//  TVRecipe.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import FoundationModels

@available(tvOS 27.3, *)
@Generable
struct TVRecipe {
    @Guide(description: "A short, appetizing recipe name")
    let name: String

    @Guide(description: "Number of servings", .range(1...8))
    let servings: Int

    @Guide(description: "Ingredients with quantities", .count(3...8))
    let ingredients: [String]

    @Guide(description: "Short preparation steps", .count(3...6))
    let steps: [String]
}
#endif
