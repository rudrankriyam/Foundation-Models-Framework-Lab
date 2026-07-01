# AGENTS.md

Guidance for agents working in the Foundation Models Framework Lab repository.

## Product

Foundation Lab is a native iOS and macOS developer tool for learning, testing,
and validating Apple's Foundation Models framework. The interface should feel
quiet, precise, and familiar to users of Apple developer tools.

The product serves two audiences without splitting into two apps:

- Developers can start from complete, editable recipes.
- They can also compose custom prompts and tools, inspect runs, compare
  adapters, and use the repository's CLI and evaluation surfaces.

## Toolchain

- Deployment targets: iOS 26.0+ and macOS 26.0+
- Supported compilers: Xcode 26.6 and Xcode 27
- Swift 6 with strict concurrency and Main Actor default isolation
- Live on-device execution requires Apple Silicon and Apple Intelligence

Xcode 27-only APIs must remain behind compiler and runtime availability checks.
Do not break Xcode 26 compatibility when adding an OS 27 example.

## Build and Validation

```bash
swiftlint lint --strict --config .swiftlint.yml
swift test

xcodebuild \
  -project FoundationLab.xcodeproj \
  -scheme 'Foundation Lab' \
  -destination 'generic/platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  build

xcodebuild \
  -project FoundationLab.xcodeproj \
  -scheme 'Foundation Lab' \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

For toolchain-specific checks, set `DEVELOPER_DIR` to the requested Xcode app.
Use separate Derived Data directories when running Xcode 26 and 27 concurrently.

## App Architecture

The app uses SwiftUI, Observation, and a feature-oriented MVVM structure.

```text
FoundationLabApp
└── AdaptiveNavigationView
    ├── Library
    ├── Playground
    └── Runs
```

- iPhone uses the modern `Tab` API.
- iPad and Mac use `NavigationSplitView` with the same three destinations.
- `NavigationCoordinator` owns scene navigation and supports App Intent routing.
- `ExperimentStore` owns the active experiment, saved experiments, persistence,
  and run history.

### Library

`ExperimentTemplate` is the canonical catalog. Every entry has one launch type:

- `recipe`: loads a `FoundationLabExperimentConfiguration` into Playground.
- `guidedLab`: opens a focused API demonstration.
- `workshop`: opens a schema or language progression.
- `workspace`: opens Adapter Comparison or FMFBench.

Do not add a second top-level destination for a feature that belongs in Library.
Runnable prompt/tool examples should be recipes unless they genuinely need a
specialized interface.

### Playground

`PlaygroundView` and `ChatViewModel` provide:

- Editable prompt and instructions
- Model runtime and reasoning controls
- Sampling and response-token controls
- Built-in tool composition
- Streaming transcript and tool events
- Voice input and speech synthesis
- Save, duplicate, Swift export, and run recording

Playground executions must create `FoundationLabExperimentRun` records with
truthful status, configuration, transcript events, timing, and token metadata.

### Runs

`RunsView` and `RunDetailView` are the evidence surface for recorded experiments.
Keep run data backward-compatible through the resilience behavior in
`FoundationLabCore`.

## Foundation Models Runtime

The reusable app runtime lives in `FoundationLabCore`. Reusable Foundation
Models utilities and tools live in the external
`https://github.com/rryam/FoundationModelsKit` package.

```swift
let session = LanguageModelSession()
let response = try await session.respond(to: "Hello")
let stream = session.streamResponse(to: "Write a story")
let structured = try await session.respond(
    to: "Suggest a book",
    generating: BookRecommendation.self
)
```

Prefer shared requests, results, provider protocols, and use cases over placing
Foundation Models execution directly in a view.

## Built-in Tools

The canonical tool implementations live in the external
`FoundationModelsKit/Sources/FoundationModelsTools` package target and are
exposed through `FoundationLabBuiltInTool`:

- Weather
- Web Search
- Contacts
- Calendar
- Reminders
- Location
- Health
- Music
- Web Metadata

Tool recipes load these implementations into Playground. Do not recreate
standalone tool screens. Preserve permission checks and require app-owned
confirmation before side effects.

## Workspaces

### Adapter Comparison

`Foundation Lab/AdapterStudio` contains the macOS adapter comparison engine and
views. It is routed through `WorkspaceView` from Library. Adapter training
and export live in `Tools/AdapterStudio` through the `fmas` CLI.

### FMFBench

`FMFBenchStudioContent` explains FMFBench stages inside the app. The canonical
runner, datasets, graders, reports, and device harness live in `Tools/FMFBench`.
Never present Simulator benchmark output as publishable device evidence.

## Voice

Voice is part of Playground, not a standalone flow.

```text
Voice/Services/
├── PermissionManager.swift
├── SpeechRecognizer.swift
├── SpeechRecognizerAudioHelpers.swift
├── SpeechSynthesizer.swift
└── SpeechSynthesizerVoiceHelpers.swift
```

`ChatViewModel+Voice.swift` coordinates recognition and synthesis. Keep audio
state cancellation-safe and surface permission failures to the user.

## Health

The Health dashboard and chat live under `Foundation Lab/Health`.

- `HealthDataManager` and `HealthKitService` read authorized HealthKit data.
- `HealthDataTool` is the only Health tool registered with Health chat.
- Never ship synthetic measurements, diagnoses, correlations, or predictions as
  if they came from the user.
- If data is unavailable, say so plainly.

## Dynamic Schemas and Languages

- Dynamic schema examples live under `Views/Examples/DynamicSchemas` and are
  grouped by `ExperimentLibraryCatalog.schemas`.
- Language examples live under `Views/Languages` and are grouped by
  `ExperimentLibraryCatalog.languages`.
- Structured output uses `@Generable`, `@Guide`, and dynamic schemas through
  shared `FoundationLabCore` capabilities where practical.

## Persistence

- Active experiments are persisted through `ExperimentPersistenceRepository`.
- Saved configurations and runs are managed by `ExperimentLibraryRepository`.
- Normalize experiment configurations at execution and persistence boundaries.
- Preserve decoding defaults for older persisted documents.

## Dependencies

- `HighlightSwift`: syntax highlighting
- `FoundationModelsKit` and `FoundationModelsTools`: external reusable runtime utilities and tools
- `FoundationLabCore`: local shared capability layer
- `LumoKit`: RAG indexing and retrieval
- `VecturaKit`: vector search, transitively used by LumoKit

Do not add a third-party dependency unless the feature clearly requires it.

## Swift and SwiftUI Conventions

- Use `@Observable` and mark shared UI state `@MainActor`.
- Use `@State` only for state owned by the view and keep it `private`.
- Prefer structured concurrency; do not introduce `DispatchQueue` for async work.
- Use `NavigationStack`, `NavigationSplitView`, typed destinations, and the modern
  `Tab` API.
- Use `foregroundStyle`, shape-based clipping, `ContentUnavailableView`, and
  semantic system styles.
- Use `Button` instead of `onTapGesture` for ordinary actions.
- Preserve Dynamic Type, VoiceOver, Voice Control, keyboard navigation, Reduce
  Motion, and 44-point minimum touch targets.
- Keep one primary type per file and name the file after that type.
- Do not add placeholders, sample values presented as real data, TODO stubs, or
  silently swallowed user-facing errors.

## Localization

`Foundation Lab/Localizable.xcstrings` contains ten languages. Remove stale
entries when deleting UI and add user-facing strings through localizable APIs.
Do not leave references to retired providers, screens, or navigation labels.

## Repository Surfaces

```text
Foundation Lab/                 Native app
FoundationLabCore/              Shared capability and experiment runtime
Tools/AFMCLI/                   afm command-line interface
Tools/FMFBench/                 Evaluation suite and device runner
Tools/AdapterStudio/            fmas adapter tooling
BookPlaygrounds/                Chapter-oriented Xcode playgrounds
skills/                         Reusable agent skills
```

Keep app, CLI, package, and documentation claims aligned with the same source of
truth. A passing build does not make an unreachable feature real.
