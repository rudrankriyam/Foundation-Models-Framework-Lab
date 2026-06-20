//
//  GenerablePatternView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

// MARK: - Generable Models

@Generable
struct Recipe {
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
    struct Ingredient {
        let name: String
        let quantity: String
        let unit: MeasurementUnit
    }

    @Generable
    enum MeasurementUnit {
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
    enum Difficulty {
        case easy
        case medium
        case hard
        case expert
    }
}

@Generable
struct MovieReview {
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
    enum Genre {
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
            description: "Use the @Generable macro with @Guide constraints for type-safe generation",
            currentPrompt: .constant(currentPrompt),
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
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
                .padding(.bottom)

                // Input based on selection
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(selectedExample == 0 ? "Cuisine Type" : "Movie Genre")
                        .font(.headline)

                    TextField(
                        selectedExample == 0 ? "Enter cuisine type" : "Enter movie genre",
                        text: selectedExample == 0 ? $cuisineInput : $movieGenreInput
                    )
                    .textFieldStyle(.roundedBorder)
                }

                // Info section
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("How @Generable Works")
                        .font(.headline)

                    Text(generableInfo(for: selectedExample))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                }

                // Results section
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding()
        }
        )
    }

    private var currentPrompt: String {
        selectedExample == 0 ? cuisineInput : movieGenreInput
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
                🍳 Generated Recipe

                Name: \(recipe.name)
                Description: \(recipe.description)

                ⏱️ Time:
                • Prep: \(recipe.prepTime) minutes
                • Cook: \(recipe.cookTime) minutes
                • Total: \(recipe.prepTime + recipe.cookTime) minutes

                🍽️ Servings: \(recipe.servings)
                📊 Difficulty: \(String(describing: recipe.difficulty))

                📝 Ingredients:
                \(formatIngredients(recipe.ingredients))

                💡 Note: Generated using @Generable pattern with type safety and constraints
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
                🎬 Movie Review

                Title: \(review.title) (\(review.year))
                Genre: \(String(describing: review.genre))
                Rating: \(String(repeating: "⭐", count: review.rating))/5

                📝 Review:
                \(review.review)

                👍 Would Recommend: \(review.wouldRecommend ? "Yes" : "No")

                💡 Note: Generated using @Generable with automatic enum handling and range constraints
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
