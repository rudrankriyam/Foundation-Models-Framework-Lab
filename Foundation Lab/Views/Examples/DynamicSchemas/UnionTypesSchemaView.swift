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
            title: "Union Types",
            description: "Use anyOf when a result can conform to more than one schema shape.",
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text to match against the union",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                contactInput = "Contact John Smith at john@example.com, works as a software engineer at Apple Inc."
                paymentInput = "Payment of $150.00 was made via credit card ending in 4242 on December 15, 2024"
                notificationInput = "System alert: Server maintenance scheduled for tonight at 11PM PST"
            },
            content: {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                // Example selector
                Picker("Example", selection: $selectedExample) {
                    ForEach(0..<examples.count, id: \.self) { index in
                        Text(examples[index]).tag(index)
                    }
                }
                .pickerStyle(.segmented)

                SchemaTextView(
                    title: "Schema Structure",
                    text: schemaDescription(for: selectedExample),
                    maximumHeight: 200,
                    usesMonospacedFont: false
                )

                // Results
                if !executor.results.isEmpty {
                    SchemaTextView(title: "Extracted Data", text: executor.results)
                }
                }
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
            Matched Variant

            The model selected the schema variant that best matches the source text.

            Extracted Data

            \(result)
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
