import Foundation
import FoundationModels
import FoundationModelsKit

public struct RunSchemaExampleUseCase: FoundationModelCapabilityUseCase {
    public static let descriptor = FoundationModelCapabilityDescriptor(
        id: "foundation-models.run-schema-example",
        displayName: "Run Schema Example",
        summary: "Runs a shared dynamic schema example using FoundationLabCore."
    )

    private let generator: FoundationModelDynamicSchemaGenerationUseCase

    public init(generator: FoundationModelDynamicSchemaGenerationUseCase = FoundationModelDynamicSchemaGenerationUseCase()) {
        self.generator = generator
    }

    public func execute(_ request: RunSchemaExampleRequest) async throws -> RunSchemaExampleResult {
        let trimmedInput = request.input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else {
            throw FoundationLabCoreError.invalidRequest("Missing input")
        }

        let plan = try makeExecutionPlan(for: request, input: trimmedInput)
        let response = try await generator.execute(
            FoundationModelDynamicSchemaGenerationRequest(
                prompt: plan.prompt,
                schema: plan.schema,
                generationOptions: request.generationOptions,
                context: request.context
            )
        )

        return RunSchemaExampleResult(
            content: plan.formatter(response.output),
            metadata: response.metadata
        )
    }
}

private extension RunSchemaExampleUseCase {
    typealias SchemaFormatter = @Sendable (GeneratedContent) -> String

    struct SchemaExecutionPlan {
        let schema: GenerationSchema
        let prompt: String
        let formatter: SchemaFormatter
    }

    struct NamedSchema {
        let schema: GenerationSchema
        let name: String
    }

    struct ClassificationData {
        let classification: String
        let confidence: Float?
        let reasoning: String?
    }

    func makeExecutionPlan(
        for request: RunSchemaExampleRequest,
        input: String
    ) throws -> SchemaExecutionPlan {
        switch request.example {
        case .basicObject:
            return try basicObjectPlan(
                presetIndex: request.presetIndex,
                input: input
            )
        case .arraySchema:
            return try arraySchemaPlan(
                presetIndex: request.presetIndex,
                input: input,
                minimumElements: request.minimumElements ?? 2,
                maximumElements: request.maximumElements ?? 5
            )
        case .enumSchema:
            return try enumSchemaPlan(
                presetIndex: request.presetIndex,
                input: input,
                customChoices: request.customChoices
            )
        }
    }

    func basicObjectPlan(
        presetIndex: Int,
        input: String
    ) throws -> SchemaExecutionPlan {
        let namedSchema = try basicObjectSchema(presetIndex: presetIndex)
        let prompt = """
        Extract the following information from this text:

        \(input)
        """

        return SchemaExecutionPlan(
            schema: namedSchema.schema,
            prompt: prompt,
            formatter: { content in
                """
                Input:
                \(input)

                Extracted Data:
                \(generatedContentJSONString(content))

                Schema Used:
                \(namedSchema.name)
                """
            }
        )
    }

    func basicObjectSchema(presetIndex: Int) throws -> NamedSchema {
        switch presetIndex {
        case 0:
            return try personSchema()
        case 1:
            return try productSchema()
        default:
            return try customObjectSchema()
        }
    }

    func personSchema() throws -> NamedSchema {
        let personSchema = DynamicGenerationSchema(
            name: "Person",
            description: "Information about a person",
            properties: [
                .init(name: "name", description: "The person's full name", schema: .init(type: String.self)),
                .init(name: "age", description: "The person's age in years", schema: .init(type: Int.self)),
                .init(name: "occupation", description: "The person's job or profession", schema: .init(type: String.self)),
                .init(name: "hobbies", description: "List of hobbies or interests", schema: .init(arrayOf: .init(type: String.self)))
            ]
        )
        return NamedSchema(
            schema: try GenerationSchema(root: personSchema, dependencies: []),
            name: "Person"
        )
    }

    func productSchema() throws -> NamedSchema {
        let specsSchema = DynamicGenerationSchema(
            name: "Specifications",
            description: "Product specifications",
            properties: [
                .init(
                    name: "display_size",
                    description: "Display size if mentioned",
                    schema: .init(type: String.self),
                    isOptional: true
                ),
                .init(
                    name: "other_specs",
                    description: "Any other specifications",
                    schema: .init(arrayOf: .init(type: String.self)),
                    isOptional: true
                )
            ]
        )
        let productSchema = DynamicGenerationSchema(
            name: "Product",
            description: "Information about a product",
            properties: [
                .init(name: "name", description: "Product name", schema: .init(type: String.self)),
                .init(name: "price", description: "Price in USD", schema: .init(type: Double.self)),
                .init(name: "specifications", description: "Product specifications", schema: specsSchema)
            ]
        )
        return NamedSchema(
            schema: try GenerationSchema(root: productSchema, dependencies: [specsSchema]),
            name: "Product"
        )
    }

    func customObjectSchema() throws -> NamedSchema {
        let customSchema = DynamicGenerationSchema(
            name: "CustomObject",
            description: "Generic custom object",
            properties: [
                .init(name: "field1", description: "A text field", schema: .init(type: String.self)),
                .init(name: "field2", description: "A number field", schema: .init(type: Int.self))
            ]
        )
        return NamedSchema(
            schema: try GenerationSchema(root: customSchema, dependencies: []),
            name: "CustomObject"
        )
    }

    func arraySchemaPlan(
        presetIndex: Int,
        input: String,
        minimumElements: Int,
        maximumElements: Int
    ) throws -> SchemaExecutionPlan {
        guard minimumElements <= maximumElements else {
            throw FoundationLabCoreError.invalidRequest("Minimum elements must be less than or equal to maximum elements")
        }

        let schema = try arraySchema(
            presetIndex: presetIndex,
            minimumElements: minimumElements,
            maximumElements: maximumElements
        )
        let prompt = """
        Extract the items from this text. Return between \(minimumElements) and \(maximumElements) items.

        Text: \(input)
        """

        return SchemaExecutionPlan(
            schema: schema,
            prompt: prompt,
            formatter: { content in
                formattedArrayOutput(
                    from: content,
                    input: input,
                    minimumElements: minimumElements,
                    maximumElements: maximumElements
                )
            }
        )
    }

    func arraySchema(
        presetIndex: Int,
        minimumElements: Int,
        maximumElements: Int
    ) throws -> GenerationSchema {
        switch presetIndex {
        case 0:
            let todoItemSchema = DynamicGenerationSchema(
                name: "TodoItem",
                description: "A single todo task",
                properties: [
                    .init(name: "task", description: "The task description", schema: .init(type: String.self)),
                    .init(
                        name: "priority",
                        description: "Priority level (high, medium, low)",
                        schema: .init(name: "Priority", anyOf: ["high", "medium", "low"]),
                        isOptional: true
                    )
                ]
            )
            let arraySchema = DynamicGenerationSchema(
                arrayOf: todoItemSchema,
                minimumElements: minimumElements,
                maximumElements: maximumElements
            )
            return try GenerationSchema(root: arraySchema, dependencies: [todoItemSchema])
        case 1:
            let ingredientSchema = DynamicGenerationSchema(
                name: "Ingredient",
                description: "A recipe ingredient",
                properties: [
                    .init(name: "name", description: "Ingredient name", schema: .init(type: String.self)),
                    .init(name: "quantity", description: "Amount needed", schema: .init(type: String.self), isOptional: true)
                ]
            )
            let arraySchema = DynamicGenerationSchema(
                arrayOf: ingredientSchema,
                minimumElements: minimumElements,
                maximumElements: maximumElements
            )
            return try GenerationSchema(root: arraySchema, dependencies: [ingredientSchema])
        default:
            let stringSchema = DynamicGenerationSchema(type: String.self)
            let arraySchema = DynamicGenerationSchema(
                arrayOf: stringSchema,
                minimumElements: minimumElements,
                maximumElements: maximumElements
            )
            return try GenerationSchema(root: arraySchema, dependencies: [])
        }
    }

    func enumSchemaPlan(
        presetIndex: Int,
        input: String,
        customChoices: [String]?
    ) throws -> SchemaExecutionPlan {
        let choices: [String]
        let fieldName: String
        let description: String

        if let customChoices, !customChoices.isEmpty {
            choices = customChoices
        } else {
            switch presetIndex {
            case 0:
                choices = ["positive", "negative", "neutral", "mixed"]
                fieldName = "sentiment"
                description = "The sentiment of the text"
            case 1:
                choices = ["urgent", "high", "medium", "low"]
                fieldName = "priority"
                description = "The priority level"
            default:
                choices = ["sunny", "cloudy", "rainy", "snowy", "foggy", "stormy"]
                fieldName = "condition"
                description = "The weather condition"
            }
            return try buildEnumSchemaPlan(
                input: input,
                fieldName: fieldName,
                description: description,
                choices: choices
            )
        }

        switch presetIndex {
        case 0:
            fieldName = "sentiment"
            description = "The sentiment of the text"
        case 1:
            fieldName = "priority"
            description = "The priority level"
        default:
            fieldName = "condition"
            description = "The weather condition"
        }

        return try buildEnumSchemaPlan(
            input: input,
            fieldName: fieldName,
            description: description,
            choices: choices
        )
    }

    func buildEnumSchemaPlan(
        input: String,
        fieldName: String,
        description: String,
        choices: [String]
    ) throws -> SchemaExecutionPlan {
        let enumSchema = DynamicGenerationSchema(
            name: "\(fieldName.capitalized)Type",
            description: description,
            anyOf: choices
        )
        let resultSchema = DynamicGenerationSchema(
            name: "ClassificationResult",
            description: "Classification result with optional confidence and reasoning",
            properties: [
                .init(name: fieldName, description: description, schema: enumSchema),
                .init(
                    name: "confidence",
                    description: "Confidence score between 0 and 1",
                    schema: .init(type: Float.self),
                    isOptional: true
                ),
                .init(
                    name: "reasoning",
                    description: "Brief explanation for the classification",
                    schema: .init(type: String.self),
                    isOptional: true
                )
            ]
        )

        let prompt = """
        Analyze the following text and classify it into one of the available categories.

        Text: \(input)
        """

        return SchemaExecutionPlan(
            schema: try GenerationSchema(root: resultSchema, dependencies: [enumSchema]),
            prompt: prompt,
            formatter: { content in
                formattedEnumOutput(
                    from: content,
                    input: input,
                    fieldName: fieldName,
                    choices: choices
                )
            }
        )
    }

    func formattedArrayOutput(
        from content: GeneratedContent,
        input: String,
        minimumElements: Int,
        maximumElements: Int
    ) -> String {
        let items = extractedArrayItems(from: content)

        return """
        Input:
        \(input)

        Extracted Items (Count: \(items.count)):
        \(formattedArrayItems(items))

        Constraints:
        - Minimum: \(minimumElements) items
        - Maximum: \(maximumElements) items
        - Actual: \(items.count) items
        - Valid: \(items.count >= minimumElements && items.count <= maximumElements ? "Yes" : "No")
        """
    }

    func formattedEnumOutput(
        from content: GeneratedContent,
        input: String,
        fieldName: String,
        choices: [String]
    ) -> String {
        let data = classificationData(from: content, fieldName: fieldName)

        return """
        Input:
        \(input)

        Classification: \(data.classification)

        Available Choices:
        \(choices.map { "- \($0)" }.joined(separator: "\n"))

        \(data.confidence.map { "Confidence: \(String(format: "%.1f%%", $0 * 100))" } ?? "")

        \(data.reasoning.map { "Reasoning: \($0)" } ?? "")

        Valid Choice: \(choices.contains(data.classification) ? "Yes" : "No (Invalid!)")
        """
    }

    func extractedArrayItems(from content: GeneratedContent) -> [GeneratedContent] {
        switch content.kind {
        case .array(let elements):
            return elements
        default:
            return []
        }
    }

    func formattedArrayItems(_ items: [GeneratedContent]) -> String {
        guard !items.isEmpty else {
            return "(none)"
        }

        return items.enumerated().map { index, item in
            "\(index + 1). \(formattedArrayItem(item))"
        }
        .joined(separator: "\n")
    }

    func formattedArrayItem(_ item: GeneratedContent) -> String {
        switch item.kind {
        case .structure(let properties, let orderedKeys):
            let parts = orderedKeys.compactMap { key -> String? in
                guard let value = properties[key] else {
                    return nil
                }
                return "\(key): \(formattedScalarValue(value))"
            }
            return parts.joined(separator: ", ")
        case .string(let value):
            return value
        default:
            return generatedContentJSONString(item)
        }
    }

    func classificationData(
        from content: GeneratedContent,
        fieldName: String
    ) -> ClassificationData {
        guard case .structure(let properties, _) = content.kind else {
            return ClassificationData(
                classification: "unknown",
                confidence: nil,
                reasoning: nil
            )
        }

        return ClassificationData(
            classification: extractedStringValue(from: properties[fieldName]) ?? "unknown",
            confidence: extractedFloatValue(from: properties["confidence"]),
            reasoning: extractedStringValue(from: properties["reasoning"])
        )
    }

    func extractedStringValue(from content: GeneratedContent?) -> String? {
        guard let content else {
            return nil
        }
        if case .string(let value) = content.kind {
            return value
        }
        return nil
    }

    func extractedFloatValue(from content: GeneratedContent?) -> Float? {
        guard let content else {
            return nil
        }
        if case .number(let value) = content.kind {
            return Float(value)
        }
        return nil
    }

    func formattedScalarValue(_ content: GeneratedContent) -> String {
        switch content.kind {
        case .string(let value):
            return value
        case .number(let value):
            return String(value)
        case .bool(let value):
            return String(value)
        default:
            return generatedContentJSONString(content)
        }
    }

    func generatedContentJSONString(_ content: GeneratedContent) -> String {
        do {
            let jsonObject = try buildJSONObject(from: content)
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
            return String(data: jsonData, encoding: .utf8) ?? String(describing: jsonObject)
        } catch {
            return "Error formatting content: \(error.localizedDescription)"
        }
    }

    func buildJSONObject(from content: GeneratedContent) throws -> Any {
        switch content.kind {
        case .string(let stringValue):
            return stringValue
        case .number(let numValue):
            return numValue
        case .bool(let boolValue):
            return boolValue
        case .null:
            return NSNull()
        case .array(let elements):
            return try elements.map { try buildJSONObject(from: $0) }
        case .structure(let properties, let orderedKeys):
            var jsonDict: [String: Any] = [:]
            for key in orderedKeys {
                if let value = properties[key] {
                    jsonDict[key] = try buildJSONObject(from: value)
                }
            }
            return jsonDict
        @unknown default:
            return String(describing: content)
        }
    }
}
