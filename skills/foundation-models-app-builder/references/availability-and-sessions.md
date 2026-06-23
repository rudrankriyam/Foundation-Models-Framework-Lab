# Availability And Sessions

Use this reference for model availability checks, one-shot sessions, persistent sessions, instructions, generation options, streaming snapshots, and prewarming.

## Availability Gate

Check availability before showing an AI-first surface. Treat unavailable models as normal product state.

```swift
import FoundationModels

struct ModelAvailabilityStatus: Sendable, Hashable {
    var isAvailable: Bool
    var reason: String?
}

func currentFoundationModelsAvailability() -> ModelAvailabilityStatus {
    switch SystemLanguageModel.default.availability {
    case .available:
        ModelAvailabilityStatus(isAvailable: true)
    case .unavailable(let reason):
        let message = switch reason {
        case .deviceNotEligible:
            "This device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            "Apple Intelligence is not enabled."
        case .modelNotReady:
            "The model is still downloading or preparing."
        @unknown default:
            "Foundation Models are unavailable."
        }

        return ModelAvailabilityStatus(isAvailable: false, reason: message)
    }
}
```

## One-Shot Session

Use a fresh session for unrelated commands so hidden conversation context does not leak across features.

```swift
import FoundationModels

func generateTitle(for topic: String) async throws -> String {
    let session = LanguageModelSession()
    let response = try await session.respond(
        to: Prompt("Generate a short, specific title for: \(topic)")
    )
    return response.content
}
```

## Instructions

Keep instructions short, domain-specific, and stable across prompts.

```swift
let instructions = Instructions("""
You are a concise writing assistant.
Prefer concrete language.
Never invent facts that are not in the prompt.
""")

let session = LanguageModelSession(instructions: instructions)
let response = try await session.respond(
    to: Prompt("Rewrite this release note for developers: \(draft)")
)
```

## Generation Options

Use low temperature for extraction, classification, summaries, and app logic. Use higher temperature for brainstorming and creative writing.

```swift
let deterministic = GenerationOptions(
    sampling: .greedy,
    temperature: 0.1,
    maximumResponseTokens: 160
)

let creative = GenerationOptions(
    sampling: .random(probabilityThreshold: 0.9),
    temperature: 0.8,
    maximumResponseTokens: 400
)

let response = try await LanguageModelSession().respond(
    to: Prompt("Suggest three feature names for an on-device AI app."),
    options: creative
)
```

## Streaming Snapshots

Foundation Models streaming returns snapshots of the current response state. Assign the latest snapshot content instead of blindly appending unless your target SDK returns deltas.

```swift
import FoundationModels
import Observation

@MainActor
@Observable
final class StreamingTextViewModel {
    var output = ""
    var isStreaming = false
    var errorMessage: String?

    private var task: Task<Void, Never>?

    func start(prompt: String) {
        task?.cancel()
        output = ""
        isStreaming = true
        errorMessage = nil

        task = Task {
            do {
                let session = LanguageModelSession()
                let stream = session.streamResponse(to: Prompt(prompt))

                for try await partial in stream {
                    guard !Task.isCancelled else { return }
                    output = partial.content
                }
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = FoundationModelsErrorPresenter.message(for: error)
            }

            isStreaming = false
        }
    }

    func cancel() {
        task?.cancel()
        isStreaming = false
    }
}
```

## Multi-Turn Session

Use a persistent session only when conversation memory is part of the feature.

```swift
let session = LanguageModelSession(
    instructions: "Remember user preferences during this conversation."
)

let first = try await session.respond(to: Prompt("I am planning a trip to Japan."))
let second = try await session.respond(to: Prompt("What should I pack?"))

print(first.content)
print(second.content)
```

## Prewarming

Prewarm when the user is likely to submit soon and the prompt prefix is stable. Avoid prewarming every route in the app.

```swift
let session = LanguageModelSession(
    instructions: "You generate short workout suggestions."
)

session.prewarm(promptPrefix: Prompt("Suggest a 20-minute workout for"))

let response = try await session.respond(
    to: Prompt("Suggest a 20-minute workout for someone new to exercise with no equipment.")
)
```

## Context Budget

Use the model's context size instead of hard-coding a token limit. On current SDKs, `SystemLanguageModel` also exposes token counting helpers for prompts, instructions, tools, schemas, and transcript entries.

```swift
func canFitPrompt(_ prompt: String) async -> Bool {
    let model = SystemLanguageModel.default
    let budget = model.contextSize
    let promptTokens: Int

    if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
        promptTokens = (try? await model.tokenCount(for: Prompt(prompt))) ?? prompt.count / 4
    } else {
        promptTokens = prompt.count / 4
    }

    return promptTokens < Int(Double(budget) * 0.7)
}
```
