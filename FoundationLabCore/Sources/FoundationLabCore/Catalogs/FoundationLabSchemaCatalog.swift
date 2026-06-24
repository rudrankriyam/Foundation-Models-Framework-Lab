import Foundation

public struct FoundationLabSchemaPreset: Sendable, Hashable, Codable, Identifiable {
    public let id: Int
    public let title: String
    public let defaultInput: String

    public init(
        id: Int,
        title: String,
        defaultInput: String
    ) {
        self.id = id
        self.title = title
        self.defaultInput = defaultInput
    }
}

public enum FoundationLabSchemaExample: String, CaseIterable, Sendable, Codable, Identifiable {
    case basicObject = "basic-object"
    case arraySchema = "array-schema"
    case enumSchema = "enum-schema"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .basicObject:
            return "Basic Object"
        case .arraySchema:
            return "Arrays"
        case .enumSchema:
            return "Enumerations"
        }
    }

    public var summary: String {
        switch self {
        case .basicObject:
            return "Create an object schema at runtime and generate data that conforms to it."
        case .arraySchema:
            return "Constrain generated arrays with minimum and maximum item counts."
        case .enumSchema:
            return "Limit generated values to a defined set of string choices."
        }
    }

    public var presets: [FoundationLabSchemaPreset] {
        switch self {
        case .basicObject:
            return [
                FoundationLabSchemaPreset(
                    id: 0,
                    title: "Person",
                    defaultInput: "John Doe is 32 years old, works as a software engineer and loves hiking."
                ),
                FoundationLabSchemaPreset(
                    id: 1,
                    title: "Product",
                    defaultInput: "The iPhone 15 Pro costs $999 and has a 6.1 inch display"
                ),
                FoundationLabSchemaPreset(
                    id: 2,
                    title: "Custom",
                    defaultInput: ""
                )
            ]
        case .arraySchema:
            return [
                FoundationLabSchemaPreset(
                    id: 0,
                    title: "Todo List",
                    defaultInput: """
                    Today I need to: buy groceries, finish the report, call mom, \
                    exercise for 30 minutes, and prepare dinner
                    """
                ),
                FoundationLabSchemaPreset(
                    id: 1,
                    title: "Recipe Ingredients",
                    defaultInput: "For this recipe you'll need eggs, flour, milk, butter, and a pinch of salt"
                ),
                FoundationLabSchemaPreset(
                    id: 2,
                    title: "Article Tags",
                    defaultInput: """
                    This article covers machine learning, artificial intelligence, \
                    deep learning, neural networks, computer vision, natural language \
                    processing, and reinforcement learning
                    """
                )
            ]
        case .enumSchema:
            return [
                FoundationLabSchemaPreset(
                    id: 0,
                    title: "Sentiment Analysis",
                    defaultInput: "The customer seems very happy with our service and left a glowing review"
                ),
                FoundationLabSchemaPreset(
                    id: 1,
                    title: "Task Priority",
                    defaultInput: "This bug fix is urgent and needs to be completed today"
                ),
                FoundationLabSchemaPreset(
                    id: 2,
                    title: "Weather Condition",
                    defaultInput: "It's a beautiful sunny day with clear skies"
                )
            ]
        }
    }

    public var defaultInput: String {
        presets.first?.defaultInput ?? ""
    }

    public func preset(at index: Int) -> FoundationLabSchemaPreset {
        let resolvedIndex = presets.indices.contains(index) ? index : presets.startIndex
        return presets[resolvedIndex]
    }

    public func choices(
        for presetIndex: Int,
        customChoices: [String]? = nil
    ) -> [String] {
        if let customChoices, !customChoices.isEmpty {
            return customChoices
        }

        guard self == .enumSchema else {
            return []
        }

        switch presetIndex {
        case 0:
            return ["positive", "negative", "neutral", "mixed"]
        case 1:
            return ["urgent", "high", "medium", "low"]
        default:
            return ["sunny", "cloudy", "rainy", "snowy", "foggy", "stormy"]
        }
    }
}
