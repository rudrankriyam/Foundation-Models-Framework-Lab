//
//  UnionTypesSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct UnionTypesSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var contactInput = "Contact John Smith at john@example.com, works as a software engineer at Apple Inc."
    @State private var paymentInput = "Payment of $150.00 was made via credit card ending in 4242 on December 15, 2024"
    @State private var notificationInput = "System alert: Server maintenance scheduled for tonight at 11PM PST"
    @State private var selectedExample = 0

    private let examples = ["Contact", "Payment", "Notification"]

    var body: some View {
        ExampleViewBase(
            title: "Union Types (anyOf)",
            description: "Create schemas that can be one of several different types",
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            onRun: { await runExample() },
            onReset: { executor.reset() },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom)

                // Schema visualization
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Schema Structure")
                        .font(.headline)

                    Text(schemaDescription(for: selectedExample))
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 8))
                }

                // Results
                if !executor.results.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Extracted Data")
                            .font(.headline)

                        ScrollView {
                            Text(executor.results)
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.gray.opacity(0.1))
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .frame(maxHeight: 200)
                    }
                }
                }
                .padding()
            }
        )
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return contactInput
        case 1: return paymentInput
        case 2: return notificationInput
        default: return ""
        }
    }

    private var bindingForSelectedExample: Binding<String> {
        switch selectedExample {
        case 0: return $contactInput
        case 1: return $paymentInput
        case 2: return $notificationInput
        default: return .constant("")
        }
    }

    private func runExample() async {
        let schema = createSchema(for: selectedExample)

        await executor.execute(
            withPrompt: "Extract the data from: \(currentInput)",
            schema: schema
        ) { result in
            """
            Union Type Detection:
            The model automatically determined which variant matches the input.

            Extracted Data:
            \(result)

            Note: anyOf schemas allow flexible data extraction when the exact type isn't known in advance.
            """
        }
    }

    private func createSchema(for index: Int) -> DynamicGenerationSchema {
        switch index {
        case 0: // Contact - Person or Company
            return createContactSchema()

        case 1: // Payment types with union schema
            return createPaymentSchema()

        case 2: // Notification types with union schema
            return createNotificationSchema()

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
        UnionTypesSchemaView()
    }
}
