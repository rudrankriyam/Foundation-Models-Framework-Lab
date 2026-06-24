//
//  FormBuilderSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationModels

struct FormBuilderSchemaView: View {
    @State private var executor = ExampleExecutor()
    @State private var formDescription = "Create a job application form with fields for personal info, experience, and skills"
    @State private var formData = """
    Name: John Smith
    Email: john.smith@email.com
    Phone: (555) 123-4567
    Years of Experience: 8
    Current Position: Senior Software Engineer
    Skills: Swift, iOS, Python, Machine Learning
    Available to Start: Immediately
    Salary Expectation: $150,000 - $180,000
    Remote Work: Yes
    """
    @State private var generationMode = 0

    private let modes = ["Build and Extract", "Build Schema", "Use Template"]

    var body: some View {
        ExampleViewBase(
            title: "Form Builder",
            description: "Build a runtime schema from a field description, then extract matching data.",
            currentPrompt: $formDescription,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Form Description",
            promptPlaceholder: "Describe the fields the form needs",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                formDescription = "Create a job application form with fields for personal info, experience, and skills"
                generationMode = 0
            },
            content: {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                GroupBox("Configuration") {
                    Picker("Mode", selection: $generationMode) {
                        ForEach(0..<modes.count, id: \.self) { index in
                            Text(modes[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .padding(.top, Spacing.small)
                }

                SchemaTextView(title: "Sample Form Data", text: formData, maximumHeight: 240)

                // Results
                if !executor.results.isEmpty {
                    SchemaTextView(title: "Schema and Extracted Data", text: executor.results)
                }
            }
        }
    )
}

    private func runExample() async {
        switch generationMode {
        case 0:
            do {
                let formSchema = createFormSchemaFromDescription(formDescription)
                let extractionSchema = try GenerationSchema(root: formSchema, dependencies: [])

                await executor.executeDynamicSchema(
                    prompt: "Extract form data from: \(formData)",
                    schema: extractionSchema
                ) { content in
                    let extractedData = formatGeneratedContent(content)
                    return """
                    Generated Form Schema

                    \(describeSchema(formSchema))

                    Extracted Data

                    \(extractedData)
                    """
                }
            } catch {
                executor.errorMessage = FoundationModelsErrorHandler.handleError(error)
                executor.result = ""
            }

        case 1:
            await executor.execute {
                let formSchema = createFormSchemaFromDescription(formDescription)
                return """
                Generated Form Schema

                \(describeSchema(formSchema))

                Use this schema to extract structured data from unstructured text.
                """
            }

        case 2:
            do {
                let predefinedSchema = createPredefinedJobApplicationSchema()
                let extractionSchema = try GenerationSchema(root: predefinedSchema, dependencies: [])

                await executor.executeDynamicSchema(
                    prompt: "Extract job application data from: \(formData)",
                    schema: extractionSchema
                ) { content in
                    let extractedData = formatGeneratedContent(content)
                    return """
                    Job Application Schema Template

                    Extracted Data

                    \(extractedData)
                    """
                }
            } catch {
                executor.errorMessage = FoundationModelsErrorHandler.handleError(error)
                executor.result = ""
            }

        default:
            await executor.execute { "The selected mode is unavailable." }
        }
    }

    private func createFormSchemaFromDescription(_ description: String) -> DynamicGenerationSchema {
        let lowercased = description.lowercased()
        var properties: [DynamicGenerationSchema.Property] = []

        // Add field types based on description content
        addPersonalInfoFields(to: &properties, for: lowercased)
        addExperienceFields(to: &properties, for: lowercased)
        addSkillsFields(to: &properties, for: lowercased)
        addCommonFields(to: &properties)

        return DynamicGenerationSchema(
            name: "FormData",
            description: "Form data extracted from user input",
            properties: properties
        )
    }

    private var exampleCode: String {
        """
        // Generate form schema from description
        func generateFormSchema(from description: String) -> DynamicGenerationSchema {
            // Analyze description to determine fields
            var properties: [DynamicGenerationSchema.Property] = []

            if description.contains("email") {
                properties.append(.init(
                    name: "email",
                    description: "Email address",
                    schema: .init(
                        type: String.self,
                        guides: [.pattern(/^[\\w.-]+@[\\w.-]+\\.\\w+$/)]
                    )
                ))
            }

            if description.contains("experience") {
                properties.append(.init(
                    name: "yearsOfExperience",
                    description: "Years of experience",
                    schema: .init(
                        type: Int.self,
                        guides: [.range(0...50)]
                    )
                ))
            }

            return DynamicGenerationSchema(
                name: "FormData",
                properties: properties
            )
        }

        // Extract data using generated schema
        let schema = generateFormSchema(from: userDescription)
        let response = try await session.respond(
            to: Prompt("Extract: " + formData),
            schema: GenerationSchema(root: schema)
        )
        """
    }
}

#Preview {
    NavigationStack {
        FormBuilderSchemaView()
    }
}
