//
//  TVRecipeView.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import SwiftUI

@available(tvOS 27.3, *)
struct TVRecipeView: View {
    @State private var model = TVRecipeModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                Text("Generate a typed recipe with @Generable and watch each field stream in.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(TVRecipeModel.dishes, id: \.self) { dish in
                        Button(dish) {
                            model.generate(dish)
                        }
                        .disabled(model.isResponding)
                    }
                }

                if model.isResponding {
                    Button("Stop", systemImage: "stop.circle", action: model.stop)
                }

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }

                if let recipe = model.recipe {
                    recipeContent(recipe)
                }
            }
            .padding(60)
        }
    }

    private func recipeContent(_ recipe: TVRecipe.PartiallyGenerated) -> some View {
        VStack(alignment: .leading, spacing: 30) {
            if let name = recipe.name {
                Text(name)
                    .font(.title2.bold())
            }
            if let servings = recipe.servings {
                Text("Serves \(servings)")
                    .font(.headline)
            }
            if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                section("Ingredients", items: ingredients)
            }
            if let steps = recipe.steps, !steps.isEmpty {
                section("Steps", items: steps)
            }
        }
    }

    private func section(_ title: LocalizedStringKey, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(.title3)
                    .focusable()
            }
        }
    }
}
#endif
