//
//  ArrayDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

struct ArrayDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var todoInput = FoundationLabSchemaExample.arraySchema.preset(at: 0).defaultInput
    @State private var ingredientsInput = FoundationLabSchemaExample.arraySchema.preset(at: 1).defaultInput
    @State private var tagsInput = FoundationLabSchemaExample.arraySchema.preset(at: 2).defaultInput
    @State private var selectedExample = 0
    @State private var minItems = 2
    @State private var maxItems = 5

    private let schemaExample = FoundationLabSchemaExample.arraySchema

    var body: some View {
        ExampleViewBase(
            title: schemaExample.title,
            description: schemaExample.summary,
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text to turn into an array",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                todoInput = schemaExample.preset(at: 0).defaultInput
                ingredientsInput = schemaExample.preset(at: 1).defaultInput
                tagsInput = schemaExample.preset(at: 2).defaultInput
                minItems = 2
                maxItems = 5
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

                    GroupBox("Array Constraints") {
                        VStack(spacing: Spacing.small) {
                            Stepper("Minimum items: \(minItems)", value: $minItems, in: 0...10)
                            Stepper("Maximum items: \(maxItems)", value: $maxItems, in: minItems...20)
                        }
                        .padding(.top, Spacing.small)
                    }

                    SchemaTextView(
                        title: "Schema Summary",
                        text: schemaInfo(for: selectedExample, minItems: minItems, maxItems: maxItems),
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
        .onChange(of: minItems) { _, newValue in
            maxItems = max(maxItems, newValue)
        }
    }

    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $todoInput
        case 1: return $ingredientsInput
        default: return $tagsInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return todoInput
        case 1: return ingredientsInput
        default: return tagsInput
        }
    }

    private func runExample() async {
        await executor.execute {
            let result = try await RunSchemaExampleUseCase().execute(
                RunSchemaExampleRequest(
                    example: .arraySchema,
                    presetIndex: selectedExample,
                    input: currentInput,
                    minimumElements: minItems,
                    maximumElements: maxItems,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            return result.content
        }
    }
}

#Preview {
    NavigationStack {
        ArrayDynamicSchemaView()
    }
}
