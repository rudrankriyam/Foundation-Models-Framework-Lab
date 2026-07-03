import FoundationModels
import Playgrounds

#Playground {
    let session = LanguageModelSession()
    let prompt = "Complete this sentence: The best way to learn programming is"

    // Greedy sampling - always chooses most likely token
    debugPrint("Greedy Sampling (Deterministic)")
    let greedyOptions = GenerationOptions(
        sampling: .greedy,
        temperature: nil // Temperature is ignored with greedy sampling
    )
    let greedyResponse = try await session.respond(to: prompt, options: greedyOptions)
    debugPrint("Response: \(greedyResponse.content)")

    // Top-K sampling with smaller K (more deterministic)
    debugPrint("Top-K Sampling (K=30, More Focused)")
    let topKSmallOptions = GenerationOptions(
        sampling: .random(top: 30, seed: nil),
        temperature: 0.7
    )
    let topKSmallResponse = try await session.respond(to: prompt, options: topKSmallOptions)
    debugPrint("Response: \(topKSmallResponse.content)")

    // Top-K sampling with larger K (more creative)
    debugPrint("Top-K Sampling (K=50, More Creative)")
    let topKLargeOptions = GenerationOptions(
        sampling: .random(top: 50, seed: nil),
        temperature: 0.7
    )
    let topKLargeResponse = try await session.respond(to: prompt, options: topKLargeOptions)
    debugPrint("Response: \(topKLargeResponse.content)")

    // Top-P sampling with conservative threshold
    debugPrint("Top-P Sampling (P=0.8, Conservative)")
    let topPConservativeOptions = GenerationOptions(
        sampling: .random(probabilityThreshold: 0.8, seed: nil),
        temperature: 0.6
    )
    let topPConservativeResponse = try await session.respond(to: prompt, options: topPConservativeOptions)
    debugPrint("Response: \(topPConservativeResponse.content)")

    // Top-P sampling with higher threshold
    debugPrint("Top-P Sampling (P=0.9, More Creative)")
    let topPCreativeOptions = GenerationOptions(
        sampling: .random(probabilityThreshold: 0.9, seed: nil),
        temperature: 0.7
    )
    let topPCreativeResponse = try await session.respond(to: prompt, options: topPCreativeOptions)
    debugPrint("Response: \(topPCreativeResponse.content)")

    // Reproducible results with seed
    debugPrint("Reproducible Results (With Seed)")
    let seededOptions = GenerationOptions(
        sampling: .random(top: 30, seed: 12345),
        temperature: 0.8
    )
    let seededResponse1 = try await session.respond(to: prompt, options: seededOptions)
    let seededResponse2 = try await session.respond(to: prompt, options: seededOptions)
    debugPrint("First response: \(seededResponse1.content)")
    debugPrint("Second response: \(seededResponse2.content)")
    debugPrint("Responses identical: \(seededResponse1.content == seededResponse2.content)")

    // System default (recommended)
    debugPrint("System Default (Recommended)")
    let systemDefaultOptions = GenerationOptions(
        sampling: nil,
        temperature: nil
    )
    let systemDefaultResponse = try await session.respond(to: prompt, options: systemDefaultOptions)
    debugPrint("Response: \(systemDefaultResponse.content)")
}
