import Foundation
import FoundationModels

private let inputCharactersPerToken = 1057.0 / 235.0
private let outputCharactersPerToken = 13680.0 / 2276.0

struct FMBenchTokenCounts: Sendable {
    let input: Int
    let output: Int
    let firstStreamUpdate: Int
    let source: FMBenchTokenCountSource
}

func estimateInputTokens(_ text: String) -> Int {
    estimateTokens(text, charactersPerToken: inputCharactersPerToken)
}

func estimateOutputTokens(_ text: String) -> Int {
    estimateTokens(text, charactersPerToken: outputCharactersPerToken)
}

func tokenCounts(
    for scenario: FMBenchScenario,
    sample: FMBenchSample,
    response: String,
    firstStreamUpdate: String,
    model: FMBenchModel
) async -> FMBenchTokenCounts {
    if model == .onDevice,
        #available(macOS 26.4, iOS 26.4, visionOS 26.4, *) {
        do {
            let systemModel = SystemLanguageModel.default
            var input = try await systemModel.tokenCount(for: Instructions(scenario.instructions))
            input += try await systemModel.tokenCount(for: Prompt(sample.prompt))

            if case .guided(let fmBenchSchema) = scenario.outputMode {
                let schema = try FMBenchSchemaFactory.make(fmBenchSchema)
                input += try await systemModel.tokenCount(for: schema)
            }

            let output = try await systemModel.tokenCount(for: Prompt(response))
            let firstUpdate = try await systemModel.tokenCount(for: Prompt(firstStreamUpdate))
            return FMBenchTokenCounts(
                input: input,
                output: output,
                firstStreamUpdate: firstUpdate,
                source: .systemTokenizer
            )
        } catch {
            // Counting should not turn a completed inference into a failed trial.
        }
    }

    return FMBenchTokenCounts(
        input: estimateInputTokens(scenario.instructions + "\n" + sample.prompt),
        output: estimateOutputTokens(response),
        firstStreamUpdate: estimateOutputTokens(firstStreamUpdate),
        source: .characterEstimate
    )
}

func renderText(from snapshot: LanguageModelSession.ResponseStream<String>.Snapshot) -> String {
    if let value = try? snapshot.rawContent.value(String.self) {
        return value
    }
    return snapshot.rawContent.jsonString
}

func renderStructured(
    from snapshot: LanguageModelSession.ResponseStream<GeneratedContent>.Snapshot
) -> String {
    snapshot.rawContent.jsonString
}

private func estimateTokens(_ text: String, charactersPerToken: Double) -> Int {
    guard !text.isEmpty else { return 0 }
    return max(1, Int(ceil(Double(text.count) / charactersPerToken)))
}
