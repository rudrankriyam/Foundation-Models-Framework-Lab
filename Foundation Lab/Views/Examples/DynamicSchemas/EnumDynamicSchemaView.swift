//
//  EnumDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModelsKit

struct EnumDynamicSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var customerInput = FoundationLabSchemaExample.enumSchema.preset(at: 0).defaultInput
    @State private var taskInput = FoundationLabSchemaExample.enumSchema.preset(at: 1).defaultInput
    @State private var weatherInput = FoundationLabSchemaExample.enumSchema.preset(at: 2).defaultInput
    @State private var selectedExample = 0
    @State private var customChoices = "excellent, good, average, poor"
    @State private var useCustomChoices = false

    private let schemaExample = FoundationLabSchemaExample.enumSchema

    var body: some View {
        ExampleViewBase(
            title: schemaExample.title,
            description: schemaExample.summary,
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text to classify",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                customerInput = schemaExample.preset(at: 0).defaultInput
                taskInput = schemaExample.preset(at: 1).defaultInput
                weatherInput = schemaExample.preset(at: 2).defaultInput
                customChoices = "excellent, good, average, poor"
                useCustomChoices = false
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
                        title: "Allowed Values",
                        text: currentChoices.joined(separator: ", "),
                        systemImage: "list.bullet",
                        maximumHeight: 140
                    )

                    GroupBox("Options") {
                        VStack(alignment: .leading, spacing: Spacing.small) {
                        Toggle("Use Custom Choices", isOn: $useCustomChoices)

                        if useCustomChoices {
                            TextField("Comma-separated choices", text: $customChoices)
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                        .padding(.top, Spacing.small)
                    }

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
        case 0: return $customerInput
        case 1: return $taskInput
        default: return $weatherInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return customerInput
        case 1: return taskInput
        default: return weatherInput
        }
    }

    private var currentChoices: [String] {
        schemaExample.choices(
            for: selectedExample,
            customChoices: useCustomChoices ? parsedCustomChoices : nil
        )
    }

    private func runExample() async {
        await executor.execute {
            let result = try await RunSchemaExampleUseCase().execute(
                RunSchemaExampleRequest(
                    example: .enumSchema,
                    presetIndex: selectedExample,
                    input: currentInput,
                    customChoices: useCustomChoices ? parsedCustomChoices : nil,
                    context: FoundationModelInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            return result.content
        }
    }

    private var parsedCustomChoices: [String] {
        customChoices
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

#Preview {
    NavigationStack {
        EnumDynamicSchemaView()
    }
}
