//
//  07_SessionWithMultipleTools.swift
//  Exploring Foundation Models
//
//  Created by Rudrank Riyam on 9/24/25.
//

import Foundation
import FoundationModels
import FoundationModelsTools
import Playgrounds

#Playground {
    // Multi-tool assistant session
    let multiToolInstructions = """
    You are a versatile personal assistant with access to multiple tools:

    - Use the calculate tool for any mathematical calculations
    - Use the getCurrentWeather tool for weather-related questions
    - Use the searchWeb tool for current information and research
    - Use the accessHealth tool for health and fitness metrics

    Choose the appropriate tool based on the user's question. If multiple tools
    might be useful, use the most relevant one and explain your choice.
    """

    let multiToolSession = LanguageModelSession(
        tools: [
            CalculatorTool(),
            WeatherTool(),
            SearchTool(),
            HealthTool()
        ],
        instructions: multiToolInstructions
    )

    // Test different types of queries
    let queries = [
        "What's 156 divided by 12?",
        "How's the weather in New York?",
        "How many steps did I take today?",
        "What's the latest news about AI?"
    ]

    for query in queries {
        debugPrint("\n--- Query: \(query) ---")
        let response = try await multiToolSession.respond(to: query)
        debugPrint("Response: \(response.content)")
    }
}

#Playground {
    // Demonstrating tool selection intelligence
    let smartSelectionInstructions = """
    You have access to various tools. Always explain which tool you're using and why.
    If you can't find an appropriate tool, explain what you would need to answer the question.
    """

    let smartSession = LanguageModelSession(
        tools: [
            CalculatorTool(),
            WeatherTool(),
            HealthTool()
        ],
        instructions: smartSelectionInstructions
    )

    let complexQuery = """
    I'm planning a workout. Can you help me figure out:
    1. If I burned 300 calories, and each calorie is about 4.184 joules, how much energy is that in joules?
    2. What's the weather like for outdoor activities?
    3. How active have I been this week?
    """

    let response = try await smartSession.respond(to: complexQuery)
    debugPrint("Smart tool selection response: \(response.content)")
}
