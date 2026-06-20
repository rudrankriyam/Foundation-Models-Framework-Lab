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
    @State private var showDetailedError = true

    private let scenarios = [
        "Basic Extraction",
        "Missing Required Fields",
        "Type Mismatch",
        "Schema Validation Failure"
    ]

    var body: some View {
        ExampleViewBase(
            title: "Error Handling",
            description: "Handle schema validation errors and edge cases gracefully",
            currentPrompt: $testInput,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedScenario = 0
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    // Scenario selector
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Error Scenario")
                            .font(.headline)

                    Picker("Scenario", selection: $selectedScenario) {
                        ForEach(0..<scenarios.count, id: \.self) { index in
                            Text(scenarios[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Options
                Toggle("Show detailed error information", isOn: $showDetailedError)
                    .padding(.vertical, 8)

                // Scenario description
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("Scenario Details", systemImage: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundStyle(.orange)

                    Text(scenarioDescription(for: selectedScenario))
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                }

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extraction Result")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(executor.errorMessage != nil ?
                                    Color.red.opacity(0.1) :
                                    Color.green.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .frame(maxHeight: 250)
                    }
                }
            }
            .padding()
        }
        )
    }

    private func runExample() async {
        let schema = createSchema(for: selectedScenario)

        await executor.execute(
            withPrompt: "Extract product information from: \(testInput)",
            schema: schema
        ) { result in
            let status = executor.errorMessage != nil ? "Error Occurred" : "Success"

            return """
            \(status)

            Schema: \(scenarios[selectedScenario])

            Result:
            \(result)

            💡 Error Handling Tips:
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
