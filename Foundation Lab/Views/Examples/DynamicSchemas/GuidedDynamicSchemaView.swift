//
//  GuidedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct GuidedDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var selectedGuideType = 0
    @State private var patternInput = "Generate 5 US phone numbers with extensions"
    @State private var rangeInput = "Generate prices between $10 and $100 for electronics"
    @State private var arrayInput = "Create a shopping list with 3-5 items each having 2-4 attributes"
    @State private var validationInput = "Generate valid email addresses for 5 employees at techcorp.com"

    private let guideTypes = [
        "Pattern Matching",
        "Number Ranges",
        "Array Constraints",
        "Complex Validation"
    ]

    var body: some View {
        ExampleViewBase(
            title: "Generation Guides",
            description: "Apply constraints to generated values using schema properties",
            currentPrompt: bindingForSelectedGuide,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedGuideType = 0
                patternInput = "Generate 5 US phone numbers with extensions"
                rangeInput = "Generate prices between $10 and $100 for electronics"
                arrayInput = "Create a shopping list with 3-5 items each having 2-4 attributes"
                validationInput = "Generate valid email addresses for 5 employees at techcorp.com"
            },
            content: {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Guide Type Selector
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Constraint Type")
                        .font(.headline)

                    Picker("Guide Type", selection: $selectedGuideType) {
                        ForEach(0..<guideTypes.count, id: \.self) { index in
                            Text(guideTypes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Guide explanation
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Label("How it works", systemImage: "info.circle")
                        .font(.headline)
                        .foregroundStyle(.blue)

                    Text(guideExplanation)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                }

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Generated Data with Constraints")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
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

    private var currentInput: String {
        switch selectedGuideType {
        case 0: return patternInput
        case 1: return rangeInput
        case 2: return arrayInput
        case 3: return validationInput
        default: return ""
        }
    }

    private var bindingForSelectedGuide: Binding<String> {
        switch selectedGuideType {
        case 0: return $patternInput
        case 1: return $rangeInput
        case 2: return $arrayInput
        case 3: return $validationInput
        default: return .constant("")
        }
    }

    private var guideExplanation: String {
        switch selectedGuideType {
        case 0:
            return """
                Pattern constraints use regex to ensure generated strings match \
                specific formats (e.g., phone numbers, postal codes, IDs)
                """
        case 1: return "Number range constraints limit numeric values to specified minimum and maximum bounds"
        case 2: return "Array constraints control the number of items in arrays using minimumElements and maximumElements"
        case 3: return "Complex validation combines multiple constraints like patterns, ranges, and enum values"
        default: return ""
        }
    }

    private func runExample() async {
        let schema = createSchema(for: selectedGuideType)

        await executor.execute(
            withPrompt: currentInput,
            schema: schema,
            formatResults: { output in
                if let data = output.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data),
                   let formatted = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]),
                   let jsonString = String(data: formatted, encoding: .utf8) {

                    // Add validation summary
                    var result = "=== Generated Data ===\n" + jsonString
                    result += "\n\n=== Constraint Validation ==="
                    result += validateConstraints(json, for: selectedGuideType)

                    return result
                }
                return output
            }
        )
    }

    private func createSchema(for index: Int) -> DynamicGenerationSchema {
        switch index {
        case 0: // Pattern Matching
            return createPhoneDirectorySchema()

        case 1: // Number Ranges
            return createProductCatalogSchema()

        case 2: // Array Constraints
            return createShoppingListSchema()

        default: // Complex Validation
            return createCompanyDirectorySchema()
        }
    }

    private var exampleCode: String {
        """
        // Using GenerationGuide constraints with DynamicGenerationSchema

        // 1. Pattern constraints for strings
        let phoneSchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.pattern(/\\(\\d{3}\\) \\d{3}-\\d{4}/)]
        )

        // 2. Range constraints for numbers
        let priceSchema = DynamicGenerationSchema(
            type: Double.self,
            guides: [.range(10.0...100.0)]
        )

        // 3. Array length constraints
        let itemsSchema = DynamicGenerationSchema(
            arrayOf: itemSchema,
            minimumElements: 3,
            maximumElements: 5
        )

        // 4. Enum constraints for valid values
        let categorySchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.anyOf(["A", "B", "C"])]
        )

        // 5. Constant values for fixed fields
        let versionSchema = DynamicGenerationSchema(
            type: String.self,
            guides: [.constant("1.0")]
        )
        """
    }
}

#Preview {
    NavigationStack {
        GuidedDynamicSchemaView()
    }
}
