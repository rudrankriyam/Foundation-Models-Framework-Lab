//
//  BasicDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModelsKit

struct BasicDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var personInput = FoundationLabSchemaExample.basicObject.preset(at: 0).defaultInput
    @State private var productInput = FoundationLabSchemaExample.basicObject.preset(at: 1).defaultInput
    @State private var customInput = FoundationLabSchemaExample.basicObject.preset(at: 2).defaultInput
    @State private var selectedExample = 0

    private let schemaExample = FoundationLabSchemaExample.basicObject

    var body: some View {
        ExampleViewBase(
            title: schemaExample.title,
            description: schemaExample.summary,
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text to structure",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                personInput = schemaExample.preset(at: 0).defaultInput
                productInput = schemaExample.preset(at: 1).defaultInput
                customInput = schemaExample.preset(at: 2).defaultInput
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Example selector
                    Picker("Example", selection: $selectedExample) {
                        ForEach(schemaExample.presets) { preset in
                            Text(preset.title).tag(preset.id)
                        }
                    }
                    .pickerStyle(.segmented)

                    SchemaTextView(
                        title: "Schema Preview",
                        text: schemaDescription,
                        maximumHeight: 260
                    )

                    // Results section
                    if !executor.results.isEmpty {
                        SchemaTextView(title: "Generated Data", text: executor.results)
                    }
                }
            }
        )
    }

    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $personInput
        case 1: return $productInput
        default: return $customInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return personInput
        case 1: return productInput
        default: return customInput
        }
    }

    private var schemaDescription: String {
        switch selectedExample {
        case 0:
            return """
            {
              "name": "Person",
              "type": "object",
              "properties": {
                "name": { "type": "string", "description": "The person's full name" },
                "age": { "type": "integer", "description": "The person's age in years" },
                "occupation": { "type": "string", "description": "The person's job or profession" },
                "hobbies": { "type": "array", "items": { "type": "string" }, "description": "List of hobbies" }
              }
            }
            """
        case 1:
            return """
            {
              "name": "Product",
              "type": "object",
              "properties": {
                "name": { "type": "string", "description": "Product name" },
                "price": { "type": "number", "description": "Price in USD" },
                "specifications": { "type": "object", "description": "Product specs" }
              }
            }
            """
        default:
            return """
            {
              "name": "CustomObject",
              "type": "object",
              "properties": {
                "field1": { "type": "string", "description": "A text field" },
                "field2": { "type": "integer", "description": "A number field" }
              }
            }
            """
        }
    }

    private func runExample() async {
        await executor.execute {
            let result = try await RunSchemaExampleUseCase().execute(
                RunSchemaExampleRequest(
                    example: .basicObject,
                    presetIndex: selectedExample,
                    input: currentInput,
                    context: FoundationModelInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            return result.content
        }
    }

    private var exampleCode: String {
        """
        // Creating a basic object schema at runtime
        let nameProperty = DynamicGenerationSchema.Property(
            name: "name",
            description: "The person's full name",
            schema: .init(type: String.self)
        )

        let ageProperty = DynamicGenerationSchema.Property(
            name: "age",
            description: "The person's age in years",
            schema: .init(type: Int.self)
        )

        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "Information about a person",
            properties: [nameProperty, ageProperty]
        )

        // Convert to GenerationSchema for use with LanguageModelSession
        let schema = try GenerationSchema(root: personSchema, dependencies: [])

        // Use the schema to extract structured data
        let response = try await session.respond(
            to: prompt, // Uses the actual user input
            schema: schema
        )
        """
    }
}

#Preview {
    NavigationStack {
        BasicDynamicSchemaView()
    }
}
