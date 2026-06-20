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
            onRun: { Task { await runExample() } },
            onReset: {
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

                    // Constraints controls
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Array Constraints")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading) {
                                Text("Min Items: \(minItems)")
                                    .font(.caption)
                                Stepper("", value: $minItems, in: 0...10)
                                    .labelsHidden()
                            }

                            Spacer()

                            VStack(alignment: .leading) {
                                Text("Max Items: \(maxItems)")
                                    .font(.caption)
                                Stepper("", value: $maxItems, in: minItems...20)
                                    .labelsHidden()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                    }

                    // Schema info
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Schema Info")
                            .font(.headline)

                        Text(schemaInfo(for: selectedExample, minItems: minItems, maxItems: maxItems))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                    }

                    HStack {
                        Button("Extract Array") {
                            Task {
                                await runExample()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(executor.isRunning || currentInput.isEmpty)

                        if executor.isRunning {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
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
                            .frame(maxHeight: 250)
                        }
                    }
                }
                .padding()
            }
        )
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
