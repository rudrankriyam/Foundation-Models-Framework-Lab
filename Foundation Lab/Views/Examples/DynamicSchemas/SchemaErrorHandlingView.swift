//
//  SchemaErrorHandlingView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct SchemaErrorHandlingView: View {
    @State private var executor = ExampleExecutor()
    @State private var testInput = "The product costs $49.99 and comes in red, blue, or green colors. It weighs 2.5 kg."
    @State private var selectedScenario = 0

    private let scenarios = [
        "Basic Extraction",
        "Missing Required Fields",
        "Type Mismatch",
        "Schema Validation Failure"
    ]

    var body: some View {
        ExampleViewBase(
            title: "Schema Errors",
            description: "Compare valid extraction with missing fields, type mismatches, and validation failures.",
            currentPrompt: $testInput,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter product details to extract",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedScenario = 0
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    GroupBox("Scenario") {
                    Picker("Scenario", selection: $selectedScenario) {
                        ForEach(0..<scenarios.count, id: \.self) { index in
                            Text(scenarios[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.top, Spacing.small)
                    }

                SchemaTextView(
                    title: "Scenario Details",
                    text: scenarioDescription(for: selectedScenario),
                    systemImage: "exclamationmark.triangle",
                    maximumHeight: 180,
                    usesMonospacedFont: false
                )

                // Results
                if !executor.results.isEmpty {
                    SchemaTextView(
                        title: "Extraction Result",
                        text: executor.results,
                        isError: executor.errorMessage != nil
                    )
                }
            }
        }
        )
    }

    private func runExample() async {
        let schema = createSchema(for: selectedScenario)

        await executor.execute(
            withPrompt: "Extract product information from: \(testInput)",
            schema: schema
        ) { result in
            return """
            Scenario: \(scenarios[selectedScenario])

            Result
            \(result)

            Error-Handling Notes
            - Use optional fields for data that might be missing
            - Provide clear descriptions to guide extraction
            - Natural language descriptions help with type conversion
            """
        }
    }

    private func createSchema(for scenario: Int) -> DynamicGenerationSchema {
        switch scenario {
        case 0: // Basic extraction
            return createBasicProductSchema()

        case 1: // Missing required fields - all fields are required
            return createStrictProductSchema()

        case 2: // Type mismatch scenario
            return createTypeSensitiveProductSchema()

        case 3: // Validation failure scenario
            return createValidatedProductSchema()

        default:
            return DynamicGenerationSchema(
                name: "Default",
                properties: []
            )
        }
    }
}

#Preview {
    NavigationStack {
        SchemaErrorHandlingView()
    }
}
