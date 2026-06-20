//
//  06_SessionWithSingleTool.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import Playgrounds

#Playground {
    // Example 1: Using calculator tool in a session
    let calculatorInstructions = """
    You are a helpful math assistant. When the user asks for calculations,
    use the calculate tool to perform the math and provide the result in a
    friendly, conversational way.
    """

    let calculatorSession = LanguageModelSession(
        tools: [CalculatorTool()],
        instructions: calculatorInstructions
    )

    let mathPrompt = "What's 45 multiplied by 23?"
    let mathResponse = try await calculatorSession.respond(to: mathPrompt)
    debugPrint("Calculator response: \(mathResponse.content)")
}

#Playground {
    // Example 2: Using weather tool in a session
    let weatherInstructions = """
    You are a friendly weather assistant. When users ask about weather,
    use the getCurrentWeather tool to fetch current conditions and provide
    helpful, conversational weather information.
    """

    let weatherSession = LanguageModelSession(
        tools: [WeatherTool()],
        instructions: weatherInstructions
    )

    let weatherPrompt = "How's the weather looking in Tokyo today?"
    let weatherResponse = try await weatherSession.respond(to: weatherPrompt)
    debugPrint("Weather response: \(weatherResponse.content)")
}

#Playground {
    // Example 3: Using search tool in a session
    let searchInstructions = """
    You are a research assistant. When users ask questions that require
    current information, use the searchWeb tool to find relevant information
    and summarize the key findings for the user.
    """

    let searchSession = LanguageModelSession(
        tools: [SearchTool()],
        instructions: searchInstructions
    )

    let searchPrompt = "Who is the current CEO of Apple?"
    let searchResponse = try await searchSession.respond(to: searchPrompt)
    debugPrint("Search response: \(searchResponse.content)")
}
