//
//  06_MultiToolCoordinationDemo.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import Foundation
import FoundationModels
import Playgrounds

#Playground {
    print("=== Multi-Tool Coordination Demo ===")
    print()

    // Create tools
    let locationTool = LocationTool()
    let weatherTool = WeatherTool()

    do {
        // Scenario 1: User asks for location first, then weather for "here"
        print("Scenario 1: Location-aware weather query")

        let session = LanguageModelSession(tools: [locationTool, weatherTool])

        // First, get user location
        print("1. Getting user location...")
        let locationResponse = try await session.respond(
            to: Prompt("Where am I located?")
        )
        print("Location response: \(locationResponse.content)")
        print()

        // Now ask for weather using "here" - the weather tool should coordinate
        print("2. Asking for weather at 'here' (should use location data)...")
        let weatherResponse = try await session.respond(
            to: Prompt("What's the weather like here?")
        )
        print("Weather response: \(weatherResponse.content)")
        print("Notice how the weather tool used the location data from the previous call!")

        // Scenario 2: Direct city query (no coordination needed)
        print("Scenario 2: Standard city weather query")

        let cityWeatherResponse = try await session.respond(
            to: Prompt("What's the weather like in London?")
        )
        print("City weather response: \(cityWeatherResponse.content)")

        // Scenario 3: Show transcript analysis
        print("Scenario 3: Transcript Analysis")

        print("Transcript entries:")
        for (index, entry) in session.transcript.enumerated() {
            switch entry {
            case .instructions:
                print("\(index): Instructions")
            case .prompt(let prompt):
                let promptText = prompt.segments.compactMap { segment -> String? in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                print("\(index): Prompt: \(promptText)")
            case .toolCalls(let calls):
                print("\(index): Tool calls: \(calls.map { $0.toolName })")
            case .toolOutput(let output):
                print("\(index): Tool output: \(output.toolName)")
            case .response(let response):
                let responseText = response.segments.compactMap { segment -> String? in
                    if case .text(let textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: " ")
                print("\(index): Model response: \(responseText.prefix(100))...")
            #if compiler(>=6.4)
            case .reasoning:
                print("\(index): Reasoning trace")
            #endif
            @unknown default:
                print("\(index): Unknown transcript entry type")
            }
        }

    } catch {
        print("Error: \(error)")
    }
}
