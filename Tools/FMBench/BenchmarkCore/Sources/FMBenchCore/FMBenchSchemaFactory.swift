import FoundationModels

// The switch is kept exhaustive and adjacent to the schema definitions for review.
// swiftlint:disable function_body_length
public enum FMBenchSchemaFactory {
    public static func make(_ schema: FMBenchSchema) throws -> GenerationSchema {
        switch schema {
        case .task:
            try object(
                named: "TaskCapture",
                properties: [
                    property("title", "Exact task title", type: String.self),
                    property("list", "Destination list", type: String.self),
                    property("dueDate", "Date formatted as YYYY-MM-DD HH:mm", type: String.self),
                    stringArrayProperty("tags", "Lowercase tags", minimum: 2, maximum: 2)
                ]
            )
        case .classification:
            try object(
                named: "Classification",
                properties: [
                    DynamicGenerationSchema.Property(
                        name: "category",
                        description: "The single best category",
                        schema: .init(
                            name: "Category",
                            anyOf: ["health", "learning", "productivity", "relationships"])
                    )
                ]
            )
        case .workout:
            try object(
                named: "WorkoutPlan",
                properties: [
                    property("focus", "Workout focus", type: String.self),
                    property("durationMinutes", "Total workout duration", type: Int.self),
                    stringArrayProperty("exercises", "Exercise names", minimum: 4, maximum: 4)
                ]
            )
        case .groundedAnswer:
            try object(
                named: "GroundedAnswer",
                properties: [
                    property("answer", "Exact concise answer", type: String.self),
                    stringArrayProperty(
                        "citations", "Supporting document IDs", minimum: 1, maximum: 3)
                ]
            )
        case .citation:
            try object(
                named: "Citation",
                properties: [
                    property("author", "Author name exactly as supplied", type: String.self),
                    property("title", "Work title exactly as supplied", type: String.self),
                    property("year", "Publication year", type: Int.self),
                    property("venue", "Publication venue exactly as supplied", type: String.self)
                ]
            )
        }
    }

    private static func object(
        named name: String,
        properties: [DynamicGenerationSchema.Property]
    ) throws -> GenerationSchema {
        let root = DynamicGenerationSchema(name: name, properties: properties)
        return try GenerationSchema(root: root, dependencies: [])
    }

    private static func property<Value: Generable>(
        _ name: String,
        _ description: String,
        type: Value.Type
    ) -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: .init(type: type)
        )
    }

    private static func stringArrayProperty(
        _ name: String,
        _ description: String,
        minimum: Int,
        maximum: Int
    ) -> DynamicGenerationSchema.Property {
        DynamicGenerationSchema.Property(
            name: name,
            description: description,
            schema: .init(
                arrayOf: .init(type: String.self),
                minimumElements: minimum,
                maximumElements: maximum
            )
        )
    }
}
// swiftlint:enable function_body_length
