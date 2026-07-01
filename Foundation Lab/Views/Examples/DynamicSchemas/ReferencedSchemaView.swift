//
//  ReferencedSchemaView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore
import FoundationModelsKit
import FoundationModels

struct ReferencedSchemaView: View {
    private static let defaultBlogInput = """
    The blog post "Understanding AI" was written by John Smith on March 15, 2024. \
    It received 3 comments: Alice said "Great article!", Bob commented "Very informative", \
    and Carol wrote "Thanks for sharing". The post has tags: AI, Machine Learning, and Technology.
    """
    private static let defaultProjectInput = """
    The SwiftUI project is managed by Sarah Johnson and has 3 team members: \
    Mike Davis (iOS Developer), Emma Wilson (Designer), and Tom Brown (Backend Engineer). \
    Mike is working on the login feature, Emma is designing the dashboard, and Tom is building the API.
    """
    private static let defaultLibraryInput = """
    The library has 3 books: "1984" by George Orwell (borrowed by John on Jan 10), \
    "To Kill a Mockingbird" by Harper Lee (borrowed by Sarah on Jan 15), and \
    "The Great Gatsby" by F. Scott Fitzgerald (available). John also borrowed "Brave New World" on Jan 20.
    """

    @State private var executor = ExampleExecutor()
    @State private var blogInput = ReferencedSchemaView.defaultBlogInput
    @State private var projectInput = ReferencedSchemaView.defaultProjectInput
    @State private var libraryInput = ReferencedSchemaView.defaultLibraryInput

    @State private var selectedExample = 0
    @State private var showReferences = true

    private let examples = ["Blog System", "Project Team", "Library Catalog"]

    var body: some View {
        ExampleViewBase(
            title: "Schema References",
            description: "Reuse shared schema definitions without duplicating their properties.",
            currentPrompt: bindingForSelectedExample,
            isRunning: executor.isRunning,
            errorMessage: executor.errorMessage,
            codeExample: exampleCode,
            promptTitle: "Source Text",
            promptPlaceholder: "Enter text to structure",
            onRun: { await runExample() },
            onReset: {
                executor.reset()
                selectedExample = 0
                showReferences = true
                blogInput = Self.defaultBlogInput
                projectInput = Self.defaultProjectInput
                libraryInput = Self.defaultLibraryInput
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

                DisclosureGroup("Schema References", isExpanded: $showReferences) {
                        Text(referenceVisualization(for: selectedExample))
                            .font(.system(.callout, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.top, Spacing.small)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
        case 0: return $blogInput
        case 1: return $projectInput
        default: return $libraryInput
        }
    }

    private var currentInput: String {
        switch selectedExample {
        case 0: return blogInput
        case 1: return projectInput
        default: return libraryInput
        }
    }

    private func runExample() async {
        do {
            let (schema, referencedSchemas) = try createSchema(for: selectedExample)
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

                Extracted Data

                \(formatReferencedContent(content))

                Referenced Schemas

                \(referencedSchemas.map { "• \($0)" }.joined(separator: "\n"))

                The referenced definitions keep shared properties consistent without duplicating the schema.
                """
            }
        } catch {
            executor.errorMessage = FoundationModelsErrorHandler.handleError(error)
            executor.result = ""
        }
    }

    private func createSchema(for index: Int) throws -> (GenerationSchema, [String]) {
        switch index {
        case 0:
            return try createBlogSchema()
        case 1:
            return try createProjectSchema()
        default:
            return try createLibrarySchema()
        }
    }
}

#Preview {
    NavigationStack {
        ReferencedSchemaView()
    }
}
