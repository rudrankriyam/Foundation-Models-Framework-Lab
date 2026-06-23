//
//  ExperimentTemplate+Recipes.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore

extension ExperimentTemplate {
    static func recipeConfiguration(
        for example: ExampleType
    ) -> FoundationLabExperimentConfiguration? {
        let templateID: String
        switch example {
        case .basicChat:
            templateID = "one-shot"
        case .streamingResponse:
            templateID = "streaming"
        case .journaling:
            templateID = "journaling"
        case .creativeWriting:
            templateID = "creative-writing"
        case .generationOptions:
            templateID = "generation-options"
        default:
            return nil
        }

        guard let template = curatedLibrary.first(where: { $0.id == templateID }),
              case .recipe(let configuration) = template.launch else {
            return nil
        }
        return configuration
    }

    static func recipeConfiguration(
        for tool: FoundationLabBuiltInTool
    ) -> FoundationLabExperimentConfiguration {
        let templateID = "tool-\(tool.rawValue)"
        guard let template = curatedLibrary.first(where: { $0.id == templateID }),
              case .recipe(let configuration) = template.launch else {
            return toolRecipeConfiguration(tool)
        }
        return configuration
    }

    static func localizedConfiguration(
        _ configuration: FoundationLabExperimentConfiguration
    ) -> FoundationLabExperimentConfiguration {
        var localized = configuration
        localized.name = String(localized: String.LocalizationValue(configuration.name))
        localized.summary = String(localized: String.LocalizationValue(configuration.summary))
        localized.prompt = String(localized: String.LocalizationValue(configuration.prompt))
        localized.instructions = String(localized: String.LocalizationValue(configuration.instructions))
        return localized
    }

    static func toolRecipeConfiguration(
        _ tool: FoundationLabBuiltInTool
    ) -> FoundationLabExperimentConfiguration {
        localizedConfiguration(FoundationLabExperimentConfiguration(
            name: tool.displayName,
            summary: toolLibrarySummary(tool),
            prompt: toolRecipePrompt(tool),
            instructions: toolRecipeInstructions(tool),
            kind: .toolUse,
            selectedTools: [tool]
        ))
    }

    static func toolLibrarySummary(_ tool: FoundationLabBuiltInTool) -> String {
        switch tool {
        case .weather:
            "Ground an answer in live conditions from Open-Meteo."
        case .web:
            "Search the web and return current, attributable results."
        case .contacts:
            "Find people with permission-aware Contacts access."
        case .calendar:
            "Read and manage events through EventKit."
        case .reminders:
            "Turn natural-language requests into real reminders."
        case .location:
            "Resolve the current location for grounded responses."
        case .health:
            "Query authorized HealthKit data with a focused tool."
        case .music:
            "Search the Apple Music catalog from a model request."
        case .webMetadata:
            "Extract useful metadata from a URL for model context."
        }
    }

}

private extension ExperimentTemplate {
    static func toolRecipePrompt(_ tool: FoundationLabBuiltInTool) -> String {
        switch tool {
        case .weather:
            "What is the current weather in Cupertino, and what should I wear for a walk?"
        case .web:
            """
            Find the latest official Apple documentation about the Foundation Models framework \
            and summarize the key capabilities.
            """
        case .contacts:
            "Find the contact whose name is closest to Alex and show the matching details."
        case .calendar:
            "Show my next calendar event and identify how much free time I have before it."
        case .reminders:
            "Show reminders due today and suggest which one I should tackle first."
        case .location:
            "Describe my current city and suggest one nearby place suitable for quiet work."
        case .health:
            "Summarize my steps, active energy, and walking distance for today using only available Health data."
        case .music:
            "Find three calm instrumental albums suitable for focused work."
        case .webMetadata:
            """
            Extract the title, description, and useful preview metadata from \
            https://developer.apple.com/apple-intelligence/.
            """
        }
    }

    static func toolRecipeInstructions(_ tool: FoundationLabBuiltInTool) -> String {
        switch tool {
        case .calendar, .contacts, .reminders:
            """
            Use the selected tool for current information. Ask for confirmation before creating or \
            changing anything, and never invent missing results.
            """
        case .health:
            """
            Use only measurements returned by the selected tool. Never invent health data, \
            diagnoses, correlations, or predictions.
            """
        default:
            """
            Use the selected tool for current information, cite the evidence it returns, \
            and never invent missing results.
            """
        }
    }
}
