import Foundation
import FoundationModels
import FoundationModelsKit

struct AFMSchemaExampleDescriptor: Sendable, Codable, Hashable {
    let id: String
    let title: String
    let summary: String
    let kind: String
    let presets: [AFMSchemaPreset]
}

struct AFMSchemaPreset: Sendable, Codable, Hashable, Identifiable {
    let id: String
    let title: String
    let defaultInput: String
}

enum AFMSchemaCatalog {
    static let examples: [AFMSchemaExampleDescriptor] = [
        AFMSchemaExampleDescriptor(
            id: "typed-person",
            title: "Typed Person",
            summary: "Generate a typed person record using @Generable output.",
            kind: "typed",
            presets: [
                AFMSchemaPreset(
                    id: "person",
                    title: "Person",
                    defaultInput: "John Doe is 32 years old, works as a software engineer, and loves hiking."
                )
            ]
        ),
        AFMSchemaExampleDescriptor(
            id: "basic-object",
            title: "Basic Object Schema",
            summary: "Generate a runtime-defined object using DynamicGenerationSchema.",
            kind: "dynamic",
            presets: [
                AFMSchemaPreset(
                    id: "person",
                    title: "Person",
                    defaultInput: "John Doe is 32 years old, works as a software engineer, and loves hiking."
                ),
                AFMSchemaPreset(
                    id: "product",
                    title: "Product",
                    defaultInput: "The iPhone 15 Pro costs $999 and has a 6.1 inch display."
                )
            ]
        ),
        AFMSchemaExampleDescriptor(
            id: "array-schema",
            title: "Array Schema",
            summary: "Generate an array with min/max constraints using DynamicGenerationSchema.",
            kind: "dynamic",
            presets: [
                AFMSchemaPreset(
                    id: "todo",
                    title: "Todo List",
                    defaultInput: "Today I need to buy groceries, finish the report, call mom, exercise for 30 minutes, and prepare dinner."
                )
            ]
        ),
        AFMSchemaExampleDescriptor(
            id: "enum-schema",
            title: "Enum Schema",
            summary: "Classify input into one of a constrained set of choices.",
            kind: "dynamic",
            presets: [
                AFMSchemaPreset(
                    id: "sentiment",
                    title: "Sentiment",
                    defaultInput: "The customer seems very happy with our service and left a glowing review."
                ),
                AFMSchemaPreset(
                    id: "priority",
                    title: "Priority",
                    defaultInput: "This bug fix is urgent and needs to be completed today."
                )
            ]
        )
    ]

    static func example(id: String) -> AFMSchemaExampleDescriptor? {
        examples.first { $0.id == id }
    }

    static func defaultChoices(for presetID: String) -> [String] {
        switch presetID {
        case "sentiment":
            ["positive", "negative", "neutral", "mixed"]
        case "priority":
            ["urgent", "high", "medium", "low"]
        default:
            ["one", "two", "three"]
        }
    }
}

@Generable
struct AFMGeneratedPerson: RuntimeCompatibleGenerable, Sendable, Codable, Hashable {
    @Guide(description: "The person's full name.")
    let name: String

    @Guide(description: "The person's age in years.")
    let age: Int

    @Guide(description: "The person's occupation.")
    let occupation: String
}
