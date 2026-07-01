//
//  ArrayDynamicSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationLabCore
import FoundationModelsKit

extension ArrayDynamicSchemaView {
    func schemaInfo(for index: Int, minItems: Int, maxItems: Int) -> String {
        let itemType = FoundationLabSchemaExample.arraySchema.preset(at: index).title
        return """
        This will extract an array of \(itemType) objects.
        • Minimum items: \(minItems)
        • Maximum items: \(maxItems)
        • The model will respect these constraints when generating the array.
        """
    }

    var exampleCode: String {
        """
        // Creating an array schema with constraints
        let itemSchema = DynamicGenerationSchema(
            name: "TodoItem",
            description: "A single todo task",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "task",
                    description: "The task description",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Array with min/max constraints
        let arraySchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 2,
            maximumElements: 5
        )

        let schema = try GenerationSchema(
            root: arraySchema,
            dependencies: [itemSchema]
        )

        // The model will generate between 2 and 5 items
        let response = try await session.respond(
            to: prompt,
            schema: schema
        )

        // Edge cases handled:
        // - Empty arrays (if minimum is 0)
        // - Maximum element enforcement
        // - Nested object arrays
        // - Simple string arrays
        """
    }
}
