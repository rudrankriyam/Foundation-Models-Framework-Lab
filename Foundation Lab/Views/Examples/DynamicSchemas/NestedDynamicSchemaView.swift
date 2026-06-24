//
//  NestedDynamicSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModels

struct NestedDynamicSchemaView: View {
    private static let defaultCompanyInput = """
    Apple Inc. is headquartered in Cupertino, California. The CEO is Tim Cook who has been leading \
    the company since 2011. Apple has several major departments including Hardware Engineering led by \
    John Ternus, Software Engineering led by Craig Federighi, and Services led by Eddy Cue. \
    The company was founded in 1976 and has over 160,000 employees worldwide.
    """
    private static let defaultOrderInput = """
    Order #12345 was placed on January 15, 2024 by Jane Smith. She ordered 2 iPhone 15 Pro units \
    at $999 each and 1 MacBook Pro 14" for $1999. The items should be shipped to 123 Main St, \
    San Francisco, CA 94105. Payment was made with Visa ending in 4242. Express shipping was selected.
    """
    private static let defaultEventInput = """
    The AI Conference 2024 will be held at the Moscone Center in San Francisco from March 15-17. \
    The keynote speaker is Dr. Sarah Johnson from Stanford University who will talk about \
    "The Future of Language Models". Other sessions include "Computer Vision Advances" by Prof. Michael Chen \
    and "Ethics in AI" by Dr. Emily Rodriguez. Registration costs $599 for early bird tickets.
    """

    @State private var executor = ExampleExecutor()
    @State private var companyInput = NestedDynamicSchemaView.defaultCompanyInput
    @State private var orderInput = NestedDynamicSchemaView.defaultOrderInput
    @State private var eventInput = NestedDynamicSchemaView.defaultEventInput

    @State private var selectedExample = 0
    @State private var nestingDepth = 2

    private let examples = ["Company Structure", "Order Details", "Event Information"]

    var body: some View {
        ExampleViewBase(
            title: "Nested Objects",
            description: "Extract nested properties into a runtime object schema.",
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text with nested details",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                nestingDepth = 2
                companyInput = Self.defaultCompanyInput
                orderInput = Self.defaultOrderInput
                eventInput = Self.defaultEventInput
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
                    text: schemaVisualization(for: selectedExample),
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
        case 0: return $companyInput
        case 1: return $orderInput
        default: return $eventInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return companyInput
        case 1: return orderInput
        default: return eventInput
        }
    }

    private func runExample() async {
        do {
            let schema = try createSchema(for: selectedExample)
            let prompt = """
            Extract the structured information from this text:

            \(currentInput)
            """
            await executor.executeDynamicSchema(
                prompt: prompt,
                schema: schema,
                generationOptions: .init(temperature: 0.1)
            ) { content in
                """
                Source Text

                \(currentInput)

                Extracted Structure

                \(NestedSchemaFormatter.formatNestedContent(content, indent: 0))

                Nesting Levels: \(NestedSchemaFormatter.countNestingLevels(content))
                """
            }
        } catch {
            executor.errorMessage = FoundationModelsErrorHandler.handleError(error)
            executor.result = ""
        }
    }

    private func createSchema(for index: Int) throws -> GenerationSchema {
        switch index {
        case 0:
            return try createCompanySchema()
        case 1:
            return try createOrderSchema()
        default:
            return try createEventSchema()
        }
    }
}

#Preview {
    NavigationStack {
        NestedDynamicSchemaView()
    }
}
