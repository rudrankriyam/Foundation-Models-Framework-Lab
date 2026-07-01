import Foundation
import FoundationModelsKit

public struct RunSchemaExampleRequest: FoundationModelCapabilityRequest {
    public let example: FoundationLabSchemaExample
    public let presetIndex: Int
    public let input: String
    public let minimumElements: Int?
    public let maximumElements: Int?
    public let customChoices: [String]?
    public let generationOptions: FoundationModelGenerationOptions?
    public let context: FoundationModelInvocationContext

    public init(
        example: FoundationLabSchemaExample,
        presetIndex: Int = 0,
        input: String,
        minimumElements: Int? = nil,
        maximumElements: Int? = nil,
        customChoices: [String]? = nil,
        generationOptions: FoundationModelGenerationOptions? = FoundationModelGenerationOptions(temperature: 0.1),
        context: FoundationModelInvocationContext
    ) {
        self.example = example
        self.presetIndex = presetIndex
        self.input = input
        self.minimumElements = minimumElements
        self.maximumElements = maximumElements
        self.customChoices = customChoices
        self.generationOptions = generationOptions
        self.context = context
    }
}
