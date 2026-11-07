# FoundationLabCore Roadmap

This roadmap tracks the shared-capability refactor after the initial package boundary landed.

## Working rules

- Shared task logic, request/result models, and reusable Foundation Models-backed providers live in `FoundationLabCore`.
- SwiftUI views and App Intents stay as thin adapters over the same capabilities.
- Additional packages are deferred until dependency pressure or platform constraints justify the split.
- Multi-turn chat stays last so the single-shot capability pattern is proven first.

## Completed

- `#110` Create `FoundationLabCore` and define dependency rules.
- `#112` Extract `GenerateBookRecommendation` as the first shared capability.
- `#113` Add the first task-oriented App Intent backed by `GenerateBookRecommendation`.
- `#114` Add the first thin CLI adapter over `GenerateBookRecommendation`.
- `#115` Extract `AnalyzeNutrition` into `FoundationLabCore`.
- `#116` Extract Weather and Web Search into shared capabilities with app, App Intent, and CLI adapters.
- `#117` Expand task-oriented App Intents with capability-backed App Shortcuts, an indexed `SupportedLanguageEntity`, and a thin localized-response intent surface.
- `#118` Extract the shared conversation/session core with transcript windowing, summarization, streaming, and reusable app/CLI adapters.
- Extract the remaining tool-backed capabilities for Contacts, Calendar, Reminders, Location, Music, Web Metadata, and Health into `FoundationLabCore`.
- Rewire the corresponding SwiftUI tool views so they invoke shared use cases instead of owning Foundation Models prompts and orchestration directly.
- Add capability-backed App Intents for nutrition, contacts, calendar, reminders, location, music, web page summary, and health queries.
- Retire the bundled CLI after the standalone Foundation Models CLI became the canonical command-line surface.
- Add shared core primitives for one-shot text, structured generation, streaming text, dynamic schema generation, model availability, supported language listing, and a basic reusable multi-turn conversation runner.
- Rewire the example/language runtime surfaces so `ExampleExecutor`, model availability, supported-language loading, multilingual response generation, dynamic schema execution, and the session-management demo flow through `FoundationLabCore`.
- Rewire chat, health chat, voice inference, RAG chat, generation-options execution, and transcript token-counting helpers so app-side adapters no longer own direct `LanguageModelSession` execution paths.

## Next up

### Final polish

- Refresh user-facing docs and sample references so the shared-capability architecture is the default story.
- Decide whether any remaining app-side `FoundationModels` imports should stay as adapter/configuration types or be wrapped behind `FoundationLabCore` enums.
- Review educational snippets and prompt/code examples that intentionally still demonstrate raw `FoundationModels` APIs so they stay clearly separate from the shared runtime path.

### Cleanup audit

- The app target still creates `LanguageModelSession` directly in several Xcode 27 lab view models (for example image input, Spotlight RAG, reasoning levels, session state, and data content) alongside teaching snippets and example-code strings. Moving that live execution behind shared capabilities is not finished.
- Remaining runtime `FoundationModels` imports in the app are primarily used for model types, `@Generable` examples, or adapter-facing configuration such as guardrails and transcript display.
