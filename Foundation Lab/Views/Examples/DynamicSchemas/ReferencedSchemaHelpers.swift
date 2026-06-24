//
//  ReferencedSchemaHelpers.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels

extension ReferencedSchemaView {
    private func createBlogPersonSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Person",
            description: "A person with a name",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Person's full name"
                )
            ]
        )
    }

    private func createCommentSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Comment",
            description: "A comment on a blog post",
            properties: [
                DynamicSchemaHelpers.referenceProperty(
                    "author",
                    referenceTo: "Person",
                    description: "Comment author"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "content",
                    type: String.self,
                    description: "Comment text"
                )
            ]
        )
    }

    func createBlogSchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createBlogPersonSchema()
        let commentSchema = createCommentSchema()

        let blogPostSchema = DynamicSchemaHelpers.schema(
            "BlogPost",
            description: "A blog post with author and comments",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "title",
                    type: String.self,
                    description: "Post title"
                ),
                DynamicSchemaHelpers.referenceProperty(
                    "author",
                    referenceTo: "Person",
                    description: "Post author"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "date",
                    type: String.self,
                    description: "Publication date"
                ),
                DynamicSchemaHelpers.referenceArrayProperty(
                    "comments",
                    referenceTo: "Comment",
                    description: "List of comments"
                ),
                DynamicSchemaHelpers.arrayProperty(
                    "tags",
                    elementSchema: .init(type: String.self),
                    description: "Post tags",
                    isOptional: true
                )
            ]
        )

        let schema = try GenerationSchema(
            root: blogPostSchema,
            dependencies: [personSchema, commentSchema]
        )

        return (schema, ["Person", "Comment"])
    }

    private func createProjectPersonSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Person",
            description: "Base person schema",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Person's name"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "role",
                    type: String.self,
                    description: "Role in the project",
                    isOptional: true
                )
            ]
        )
    }

    private func createTaskSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Task",
            description: "A project task",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "description",
                    type: String.self,
                    description: "Task description"
                ),
                DynamicSchemaHelpers.referenceProperty(
                    "assignee",
                    referenceTo: "Person",
                    description: "Person assigned to this task",
                    isOptional: true
                )
            ]
        )
    }

    func createProjectSchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createProjectPersonSchema()
        let taskSchema = createTaskSchema()

        let projectSchema = DynamicSchemaHelpers.schema(
            "Project",
            description: "Project with team and tasks",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Project name"
                ),
                DynamicSchemaHelpers.referenceProperty(
                    "manager",
                    referenceTo: "Person",
                    description: "Project manager"
                ),
                DynamicSchemaHelpers.referenceArrayProperty(
                    "team",
                    referenceTo: "Person",
                    description: "Team members"
                ),
                DynamicSchemaHelpers.referenceArrayProperty(
                    "tasks",
                    referenceTo: "Task",
                    description: "Project tasks",
                    isOptional: true
                )
            ]
        )

        let schema = try GenerationSchema(
            root: projectSchema,
            dependencies: [personSchema, taskSchema]
        )

        return (schema, ["Person", "Task"])
    }

    private func createLibraryPersonSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Person",
            description: "Library member",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "name",
                    type: String.self,
                    description: "Member name"
                )
            ]
        )
    }

    private func createBookSchema() -> DynamicGenerationSchema {
        DynamicSchemaHelpers.schema(
            "Book",
            description: "Library book",
            properties: [
                DynamicSchemaHelpers.typedProperty(
                    "title",
                    type: String.self,
                    description: "Book title"
                ),
                DynamicSchemaHelpers.typedProperty(
                    "author",
                    type: String.self,
                    description: "Book author"
                ),
                DynamicSchemaHelpers.referenceProperty(
                    "borrowedBy",
                    referenceTo: "Person",
                    description: "Person who borrowed this book",
                    isOptional: true
                ),
                DynamicSchemaHelpers.typedProperty(
                    "borrowDate",
                    type: String.self,
                    description: "Date when book was borrowed",
                    isOptional: true
                )
            ]
        )
    }

    func createLibrarySchema() throws -> (GenerationSchema, [String]) {
        let personSchema = createLibraryPersonSchema()
        let bookSchema = createBookSchema()

        let librarySchema = DynamicSchemaHelpers.schema(
            "Library",
            description: "Library catalog",
            properties: [
                DynamicSchemaHelpers.referenceArrayProperty(
                    "books",
                    referenceTo: "Book",
                    description: "All books in the library"
                ),
                DynamicSchemaHelpers.referenceArrayProperty(
                    "members",
                    referenceTo: "Person",
                    description: "Library members",
                    isOptional: true
                )
            ]
        )

        let schema = try GenerationSchema(
            root: librarySchema,
            dependencies: [personSchema, bookSchema]
        )

        return (schema, ["Person", "Book"])
    }

    func referenceVisualization(for index: Int) -> String {
        switch index {
        case 0:
            return """
            📦 Person (reusable schema)
            └── Used by: BlogPost.author, Comment.author

            📦 Comment (reusable schema)
            └── Used by: BlogPost.comments[]

            BlogPost (root schema)
            ├── author → Person (reference)
            └── comments → [Comment] (reference)
            """
        case 1:
            return """
            📦 Person (base schema)
            └── Extended by: Developer, Designer

            📦 Task (reusable schema)
            └── Used by: Project.tasks[], Person.assignedTasks[]

            Project (root schema)
            ├── manager → Person (reference)
            ├── team → [Person] (reference)
            └── tasks → [Task] (reference)
            """
        default:
            return """
            📦 Person (reusable schema)
            └── Used by: Book.borrowedBy, Loan.borrower

            📦 Book (reusable schema)
            └── Used by: Library.books[], Loan.book

            📦 Loan (combines references)
            ├── book → Book (reference)
            └── borrower → Person (reference)
            """
        }
    }

    func formatReferencedContent(_ content: GeneratedContent) -> String {
        var result = ""
        var processedRefs = Set<String>()

        result = formatValue(content, indent: 0, processedRefs: &processedRefs)
        return result.isEmpty ? "No data" : result
    }

    private func formatPrimitiveValue(_ value: GeneratedContent) -> String {
        switch value.kind {
        case .string(let str):
            return "\"\(str)\""
        case .number(let num):
            return String(num)
        case .bool(let bool):
            return String(bool)
        case .null:
            return "null"
        // These cases should never be reached since formatPrimitiveValue is only
        // called from the default case in formatStructureProperty
        case .structure, .array:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }

    private func formatArrayValue(
        _ elements: [GeneratedContent],
        indent: Int,
        processedRefs: inout Set<String>
    ) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var output = "["
        for element in elements {
            output += formatValue(element, indent: indent + 1, processedRefs: &processedRefs)
        }
        output += "\n\(indentStr)]"
        return output
    }

    private func formatStructureProperty(
        _ val: GeneratedContent,
        key: String,
        indent: Int,
        processedRefs: inout Set<String>
    ) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var output = "\n\(indentStr)\(key): "

        switch val.kind {
        case .structure:
            // This is a referenced object
            if !processedRefs.contains(key) {
                processedRefs.insert(key)
                output += "(ref)"
            }
            output += formatValue(val, indent: indent + 1, processedRefs: &processedRefs)
        case .array(let elements):
            output += formatArrayValue(elements, indent: indent, processedRefs: &processedRefs)
        default:
            output += formatPrimitiveValue(val)
        }

        return output
    }

    func formatValue(_ value: GeneratedContent, indent: Int, processedRefs: inout Set<String>) -> String {
        var output = ""

        switch value.kind {
        case .structure(let properties, let orderedKeys):
            for key in orderedKeys {
                if let val = properties[key] {
                    output += formatStructureProperty(val, key: key, indent: indent, processedRefs: &processedRefs)
                }
            }
        case .array(let elements):
            output += formatArrayValue(elements, indent: indent, processedRefs: &processedRefs)
        default:
            output += formatPrimitiveValue(value)
        }

        return output
    }

    var exampleCode: String {
        """
        // Creating schemas with references

        // Define a reusable Person schema
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "A person",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "name",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Define a Comment schema that references Person
        let commentSchema = DynamicGenerationSchema(
            name: "Comment",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "author",
                    schema: .init(referenceTo: "Person")  // Reference!
                ),
                DynamicGenerationSchema.Property(
                    name: "content",
                    schema: .init(type: String.self)
                )
            ]
        )

        // Main schema using references
        let blogPostSchema = DynamicGenerationSchema(
            name: "BlogPost",
            properties: [
                DynamicGenerationSchema.Property(
                    name: "author",
                    schema: .init(referenceTo: "Person")
                ),
                DynamicGenerationSchema.Property(
                    name: "comments",
                    schema: .init(arrayOf: .init(referenceTo: "Comment"))
                )
            ]
        )

        // Register all schemas in dependencies
        let schema = try GenerationSchema(
            root: blogPostSchema,
            dependencies: [personSchema, commentSchema]
        )

        // Benefits:
        // - Avoid duplication
        // - Maintain consistency
        // - Enable circular references
        // - Simplify complex schemas
        """
    }
}
