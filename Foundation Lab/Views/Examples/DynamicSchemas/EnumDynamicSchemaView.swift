//
//  EnumDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

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
            onRun: { await runExample() },
            onReset: {
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

                    // Current choices display
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Available Choices")
                            .font(.headline)

                        Text(currentChoices.joined(separator: ", "))
                            .font(.system(.body, design: .monospaced))
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(.rect(cornerRadius: 8))
                    }

                    // Custom choices option
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Toggle("Use Custom Choices", isOn: $useCustomChoices)
                            .font(.caption)

                        if useCustomChoices {
                            TextField("Comma-separated choices", text: $customChoices)
                                .textFieldStyle(.roundedBorder)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(.rect(cornerRadius: 8))

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
                    context: CapabilityInvocationContext(
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
