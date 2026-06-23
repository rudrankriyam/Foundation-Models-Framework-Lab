import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()

    // Example 1: Focused request
    let response1 = try await session.respond(to: "Generate five related workout routines for beginners")
    print("Focused: \(response1.content)")

    // Example 2: With examples
    let response2 = try await session.respond(to:
                                               "Generate five workout routines for someone new to exercise. Each should be 2-3 words " +
                                               "like 'Morning Yoga' or 'Quick Cardio'")
    print("With examples: \(response2.content)")
}
