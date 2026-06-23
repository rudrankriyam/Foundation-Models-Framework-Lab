//
//  GenerablePatternHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension GenerablePatternView {
    func generableInfo(for index: Int) -> String {
        if index == 0 {
            return """
            The @Generable macro automatically:
            • Creates schemas from Swift types
            • Enforces type safety
            • Applies @Guide constraints:
              - .count(3...5) for ingredients array
              - Descriptive hints for better generation
            • Handles nested types and enums
            """
        } else {
            return """
            Movie Review demonstrates:
            • Enum types for genres
            • Range constraints (.range(1...5) for ratings)
            • Boolean fields
            • Mixed data types (String, Int, Bool)
            • Automatic schema generation
            """
        }
    }

    var exampleCode: String {
        """
        // Define your types with @Generable
        @Generable
        struct Recipe {
            @Guide(description: "A creative recipe name")
            let name: String

            @Guide(.count(3...5), description: "Main ingredients")
            let ingredients: [Ingredient]

            @Guide(description: "Difficulty level")
            let difficulty: Difficulty

            @Generable
            struct Ingredient {
                let name: String
                let quantity: String
                let unit: MeasurementUnit
            }

            @Generable
            enum Difficulty {
                case easy, medium, hard, complex
            }
        }

        // Use it directly with the session
        let response = try await session.respond(
            to: "Create an Italian recipe",
            generating: Recipe.self
        )

        let recipe = response.content
        // recipe is now a fully typed Recipe instance!
        """
    }
}
