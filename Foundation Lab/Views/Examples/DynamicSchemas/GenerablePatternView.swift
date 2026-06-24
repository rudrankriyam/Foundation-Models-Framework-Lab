//
//  GenerablePatternView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import FoundationModels
import FoundationModelsKit
import SwiftUI

// MARK: - Generable Models

@Generable
struct Recipe: RuntimeCompatibleGenerable {
    @Guide(description: "A creative and appetizing recipe name")
    let name: String

    @Guide(description: "Brief description of the dish")
    let description: String

    @Guide(description: "List of main ingredients", .count(3...5))
    let ingredients: [Ingredient]

    @Guide(description: "Difficulty level of the recipe")
    let difficulty: Difficulty

    @Guide(description: "Preparation time in minutes")
    let prepTime: Int

    @Guide(description: "Cooking time in minutes")
    let cookTime: Int

    @Guide(description: "Number of servings")
    let servings: Int

    @Generable
    struct Ingredient: RuntimeCompatibleGenerable {
        let name: String
        let quantity: String
        let unit: MeasurementUnit
    }

    @Generable
    enum MeasurementUnit: RuntimeCompatibleGenerable {
        case cups
        case tablespoons
        case teaspoons
        case ounces
        case pounds
        case grams
        case milliliters
        case pieces
    }

    @Generable
    enum Difficulty: RuntimeCompatibleGenerable {
        case easy
        case medium
        case hard
        case complex
    }
}

@Generable
struct MovieReview: RuntimeCompatibleGenerable {
    @Guide(description: "The movie title")
    let title: String

    @Guide(description: "Year the movie was released")
    let year: Int

    @Guide(description: "Movie genre")
    let genre: Genre

    @Guide(description: "Rating out of 5 stars", .range(1...5))
    let rating: Int

    @Guide(description: "A brief review of the movie")
    let review: String

    @Guide(description: "Whether you would recommend this movie")
    let wouldRecommend: Bool

    @Generable
    enum Genre: RuntimeCompatibleGenerable {
        case action
        case comedy
        case drama
        case horror
        case sciFi
        case romance
        case documentary
        case animated
    }
}

// MARK: - View

struct GenerablePatternView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedExample = 0
    @State private var cuisineInput = "Italian"
    @State private var movieGenreInput = "sci-fi"

    private let examples = ["Recipe Generator", "Movie Review"]

    var body: some View {
        ExampleViewBase(
            title: "@Generable Pattern",
            description: "Compare compile-time @Generable types with runtime schemas.",
            currentPrompt: promptBinding,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: selectedExample == 0 ? "Cuisine" : "Movie Genre",
            promptPlaceholder: selectedExample == 0 ? "Enter a cuisine" : "Enter a movie genre",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                cuisineInput = "Italian"
                movieGenreInput = "sci-fi"
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                // Info section
                SchemaTextView(
                    title: "How @Generable Works",
                    text: generableInfo(for: selectedExample),
                    systemImage: "info.circle",
                    maximumHeight: 180,
                    usesMonospacedFont: false
                )

                // Results section
                if !executor.results.isEmpty {
                    SchemaTextView(title: "Generated Data", text: executor.results)
                }
            }
        }
        )
    }

    private var currentPrompt: String {
        selectedExample == 0 ? cuisineInput : movieGenreInput
    }

    private var promptBinding: Binding<String> {
        selectedExample == 0 ? $cuisineInput : $movieGenreInput
    }

    private func runExample() async {
        if selectedExample == 0 {
            let prompt = """
            Create a delicious \(cuisineInput) recipe that would be perfect for a dinner party.
            Make it sound appetizing and include specific measurements for ingredients.
            """

            await executor.executeStructured(
                prompt: prompt,
                type: Recipe.self
            ) { recipe in
                """
                Generated Recipe

                Name: \(recipe.name)
                Description: \(recipe.description)

                Time
                Prep: \(recipe.prepTime) minutes
                Cook: \(recipe.cookTime) minutes
                Total: \(recipe.prepTime + recipe.cookTime) minutes

                Servings: \(recipe.servings)
                Difficulty: \(String(describing: recipe.difficulty))

                Ingredients
                \(formatIngredients(recipe.ingredients))
                """
            }
        } else {
            let prompt = """
            Write a review for a popular \(movieGenreInput) movie.
            Include your honest opinion and rating.
            """

            await executor.executeStructured(
                prompt: prompt,
                type: MovieReview.self
            ) { review in
                """
                Movie Review

                Title: \(review.title) (\(review.year))
                Genre: \(String(describing: review.genre))
                Rating: \(review.rating)/5

                Review
                \(review.review)

                Would Recommend: \(review.wouldRecommend ? "Yes" : "No")
                """
            }
        }
    }

    private func formatIngredients(_ ingredients: [Recipe.Ingredient]) -> String {
        ingredients.enumerated().map { index, ingredient in
            "  \(index + 1). \(ingredient.quantity) \(String(describing: ingredient.unit)) \(ingredient.name)"
        }.joined(separator: "\n")
    }
}

#Preview {
    NavigationStack {
        GenerablePatternView()
    }
}
