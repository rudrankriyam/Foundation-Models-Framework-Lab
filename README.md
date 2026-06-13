# Foundation Models Framework Lab

<div align="center">
  <table>
    <tr>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Examples.png" alt="FMF examples - One-shot prompt interface showing a haiku generation example with prompt input, reset/run buttons, suggestions, and resulting haiku about destiny" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Examples</strong>
      </td>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Tools.png" alt="FMF tools - Tools page showing various utility options including Weather, Web Search, Contacts, Calendar, Reminders, Location, Health, Music, and Web Metadata tools" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Tools</strong>
      </td>
    </tr>
    <tr>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Chat.png" alt="FMF chat - Chat interface displaying a conversation about the meaning of life, with user messages on the right and AI responses on the left, including a detailed philosophical answer" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Chat</strong>
      </td>
      <td align="center" style="padding: 15px;">
        <img src="images/FMF_Languages.png" alt="FMF languages - Languages page showing various language options and language selection interface for the Foundation Models framework" width="500" style="border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"/>
        <br/>
        <strong>FMF Languages</strong>
      </td>
    </tr>
  </table>
</div>

## Requirements

- iOS 26.0+ or macOS 26.0+
- **Xcode 27 beta is required** for the latest Foundation Models APIs used in this repo
- Apple Intelligence enabled
- Compatible Apple device with Apple Silicon

## Xcode 27 Foundation Models Notes

Xcode 27 adds several Foundation Models surfaces that are not available in the Xcode 26 SDK:

- `PrivateCloudComputeLanguageModel` for Private Cloud Compute-backed language model sessions, with availability, quota usage, context size, supported languages, and network/quota/service errors.
- `LanguageModel` and executor APIs that abstract over `SystemLanguageModel` and `PrivateCloudComputeLanguageModel`.
- Image attachments and references through `Attachment<ImageAttachmentContent>` and `ImageReference`, including UIKit convenience initializers through the new `_FoundationModels_UIKit` overlay.
- `GenerationOptions.samplingMode`, replacing the deprecated `sampling` spelling.
- `GenerationOptions.toolCallingMode` with `.allowed`, `.required`, and `.disallowed`.
- Foundation Models types are now available to watchOS 27 for many prompting, schema, transcript, tool, and feedback surfaces, while tvOS remains unavailable.

## Try it on TestFlight

You can now try Foundation Lab on TestFlight! Join the beta: [https://testflight.apple.com/join/JWR9FpP3](https://testflight.apple.com/join/JWR9FpP3)

## Automated TestFlight uploads

This repo includes a repo-local ASC workflow in `.asc/workflow.json` and a GitHub Actions workflow in `.github/workflows/foundation-lab-testflight.yml` that uploads the iOS app to the external TestFlight Beta group whenever app changes land on `main`.

GitHub Actions expects these repository secrets:

- `ASC_KEY_ID`
- `ASC_ISSUER_ID`
- `ASC_PRIVATE_KEY_B64`

It also expects these repository variables:

- `FOUNDATION_LAB_APP_ID`
- `FOUNDATION_LAB_EXTERNAL_GROUP_ID`
- `FOUNDATION_LAB_BUNDLE_ID`
- `FOUNDATION_LAB_TEAM_ID`

## Getting Started

- Clone the repository
- Open `FoundationLab.xcodeproj` in Xcode
- Ensure you have a device with Apple Intelligence enabled
- Build and run the project
- Explore the different capabilities through the examples!

## Repository Map

Foundation Models Framework Lab is the canonical home for the app, reusable
runtime, developer tools, and practical evaluations:

| Surface | Location | Purpose |
| --- | --- | --- |
| Foundation Lab | [`Foundation Lab`](Foundation%20Lab) | iOS and macOS examples, tools, Studio workspaces, and interactive model exploration |
| FoundationLabCore | [`FoundationLabCore`](FoundationLabCore) | UI-independent capabilities and the shared production runtime used by the app and CLI |
| FoundationModelsKit | [`Packages/FoundationModelsKit`](Packages/FoundationModelsKit) | Public transcript, token-budget, history, system-tool, and web-tool products |
| `afm` | [`Tools/AFMCLI`](Tools/AFMCLI) | Native Foundation Models command-line workflows |
| AppBench | [`Tools/AppBench`](Tools/AppBench) | Publishable app-shaped quality, safety, and performance evaluation |
| Adapter Studio | [`Foundation Lab/AdapterStudio`](Foundation%20Lab/AdapterStudio) and [`Tools/AdapterStudio`](Tools/AdapterStudio) | macOS adapter comparison and the `fmas` training/export workflow |

The former standalone
[CLI](https://github.com/rudrankriyam/Foundation-Models-Framework-CLI),
[AppBench](https://github.com/rudrankriyam/Foundation-Models-AppBench), and
[Adapter Studio](https://github.com/rudrankriyam/Foundation-Models-Adapter-Studio)
repositories are archived and redirect here. The public
[`rryam/FoundationModelsKit`](https://github.com/rryam/FoundationModelsKit)
repository continues to serve versioned 2.x consumers; active package development
lives in this repository. Agent orchestration remains intentionally separate in
[`CoreAgent`](https://github.com/rudrankriyam/CoreAgent).

## Command-Line Interface

The `afm` CLI now ships from this repository and uses the same `FoundationLabCore` and
`FoundationModelsKit` implementation as the app. Its command layer stays focused on
argument parsing, terminal output, file-backed schemas, and dynamic tool manifests
instead of maintaining a second Foundation Models runtime.

Install the current release with Homebrew:

```bash
brew tap rudrankriyam/tap
brew install afm
```

Or build and run it from this checkout:

```bash
swift build --product afm
swift run afm --help
swift run afm model status
swift run afm session respond --prompt "Summarize Foundation Models."
```

The CLI supports streaming, multi-turn sessions, content tagging, typed and dynamic
schemas, `.fmadapter` packages, tool manifests, transcript export, JSON automation,
and Feedback Assistant attachments. See [`Tools/AFMCLI/README.md`](Tools/AFMCLI/README.md)
for the full command reference.

AFM releases use `afm-vx.y.z` tags so CLI binaries and Homebrew updates remain separate
from Foundation Lab app releases.

## Foundation Models AppBench

AppBench now ships from this repository as the practical evaluation suite for Apple
Foundation Models. It contains ten app-shaped workloads with fixed synthetic fixtures,
a separate safety guardrail suite, sustained-generation and context-limit scenarios,
deterministic graders, and separate quality and performance reporting.

Run the canonical Mac benchmark from the repository root:

```bash
swift run appbench list
swift run appbench --suite quick --model on-device
swift run appbench --suite quick --all-samples --model on-device
swift run appbench --suite full --warmups 5 --repetitions 20 \
  --json Tools/AppBench/Results/run.json \
  --markdown Tools/AppBench/Results/run.md
```

Official macOS results come from the CLI. Official iPhone and iPad results require the
small signed `AppBenchDeviceRunner` harness on a physical Apple Intelligence device;
simulator output is only valid for build and interface checks.

The complete corpus, methodology, research notes, historical baseline, nested package,
and device runner live in [`Tools/AppBench`](Tools/AppBench).

## Foundation Models Adapter Studio

Adapter Studio is now built into Foundation Lab as a macOS **Adapter Comparison**
workspace. Import a `.fmadapter` package, submit one prompt to fresh base and adapter
sessions, inspect both streams independently, and compare time-to-first-token and total
duration. Those concurrent timings are interactive diagnostics; AppBench remains the
surface for publishable benchmark results.

The companion `fmas` Python CLI keeps Apple's adapter-training workflow available:

```bash
python3.11 -m venv .venv-fmas
source .venv-fmas/bin/activate
python -m pip install -e Tools/AdapterStudio
fmas init
fmas setup
fmas train-adapter --help
fmas export --help
```

The Swift workspace, CLI reference, exit-code contract, and tests are documented in
[`Tools/AdapterStudio`](Tools/AdapterStudio).

## Swift Packages

The repository also distributes reusable Swift package products for applications that do not need the Foundation Lab UI:

- `FoundationModelsKit` provides transcript history transforms, token estimation, and context-budget utilities.
- `FoundationModelsTools` provides calendar, contacts, health, location, music, reminders, weather, and web tools. It re-exports `FoundationModelsKit` for compatibility with existing users.
- `FoundationLabCore` provides the UI-independent capability requests, results, use cases, and Foundation Models providers used by the Lab app.
- `AppBenchCore` provides the benchmark corpus, deterministic graders, runner, metrics, and reports.
- `BenchmarkCore` preserves the original AppBench package product name as a compatibility alias.
- `appbench` is the canonical macOS benchmark executable.

Apple Evaluations support intentionally lives in the separate macOS 27 package at
`Tools/AppBench/Evaluations`, rather than the root cross-platform package. Its
`appbench-evaluate` command converts recorded AppBench JSON into native evaluation
results without running the model again. Generic inspection, comparison, JSONL,
and `.xcresult` export are provided by the standalone
[`xceval`](https://github.com/rudrankriyam/Evaluations-Framework-CLI) CLI. Neither
Evaluations integration is linked into or shown by the iOS app.

Add the repository to your package dependencies:

```swift
dependencies: [
    .package(
        url: "https://github.com/rudrankriyam/Foundation-Models-Framework-Lab.git",
        branch: "main"
    )
]
```

Then select the products needed by your target:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(
            name: "FoundationModelsKit",
            package: "foundation-models-framework-lab"
        ),
        .product(
            name: "FoundationModelsTools",
            package: "foundation-models-framework-lab"
        ),
        .product(
            name: "FoundationLabCore",
            package: "foundation-models-framework-lab"
        ),
        .product(
            name: "AppBenchCore",
            package: "foundation-models-framework-lab"
        )
    ]
)
```

The original `rryam/FoundationModelsKit` repository remains available for applications pinned to 2.x releases.

## Agent Skill

This repo includes a `foundation-models-app-builder` agent skill with self-contained Swift recipes for Foundation Models app development. It gives agents packaged patterns for sessions, structured generation, dynamic schemas, tool calling, RAG, voice, HealthKit, App Intents, multilingual support, and shared capability extraction without needing to inspect this repo's source files.

It also includes a `foundation-models-os27-updater` skill for migrating any Foundation Models project from OS 26-era APIs to OS 27/Xcode 27. Use it when updating apps, packages, examples, and docs for Private Cloud Compute, shared `LanguageModel` execution, context windows, image input, tool-calling modes, dynamic profiles, reasoning controls, transcripts, custom executors, and build verification.

The skill is organized into focused references:

```text
skills/
  foundation-models-app-builder/
    SKILL.md
    references/
      architecture.md
      availability-and-sessions.md
      structured-generation.md
      dynamic-schemas.md
      tool-calling.md
      rag.md
      voice.md
      app-intents.md
      healthkit.md
      multilingual.md
      common-errors.md
  foundation-models-os27-updater/
    SKILL.md
```

Install it with the open skills CLI:

```bash
npx skills add rudrankriyam/Foundation-Models-Framework-Lab --skill foundation-models-app-builder
npx skills add rudrankriyam/Foundation-Models-Framework-Lab --skill foundation-models-os27-updater
```

To target a specific agent explicitly:

```bash
npx skills add rudrankriyam/Foundation-Models-Framework-Lab --skill foundation-models-app-builder --agent codex
npx skills add rudrankriyam/Foundation-Models-Framework-Lab --skill foundation-models-app-builder --agent claude-code
npx skills add rudrankriyam/Foundation-Models-Framework-Lab --skill foundation-models-os27-updater --agent codex
```

## What's Inside

The app has four main sections:

### Chat
Multi-turn conversations with context management, streaming responses, and a feedback system. Includes automatic context window management with session summarization when needed.

### Tools
Nine system integration tools that extend the model's capabilities:
- **Weather** - Current weather for any location (OpenMeteo API)
- **Web Search** - Keyless Search1API (free, limited)
- **Contacts** - Search and access system contacts
- **Calendar** - Create and manage calendar events
- **Reminders** - AI-assisted reminder creation with priority levels
- **Location** - Current location and geocoding
- **Health** - HealthKit integration for health data queries
- **Music** - Apple Music search (requires subscription)
- **Web Metadata** - Extract metadata and generate social media summaries

### Voice Interface
Talk to the model using speech:
- Voice-to-text with real-time transcription
- Text-to-speech responses
- Create reminders by voice
- Audio-reactive visualization
- Handles all permissions automatically

### Health Dashboard
AI-powered health tracking with HealthKit:
- Personal health coach with contextual insights
- Trend analysis and correlations
- Predictive analytics
- Weekly summaries and personalized health plans
- Multiple health metrics tracking

### Integrations Hub
Three sections for exploring advanced features:
- **Tools** - All nine system integration examples
- **Schemas** - Dynamic schema examples from basic to expert level
- **Languages** - Multilingual features and language detection

### Examples
Ten different example types showing framework capabilities:
- One-shot prompts
- Journaling
- Creative writing
- Structured data generation
- Streaming responses
- Model availability checking
- Generation guides
- Generation options (temperature, tokens, fitness)
- Health dashboard
- RAG chat with document indexing and search

## Features

### Core Capabilities
- **Chat**: Multi-turn conversations with context management
- **Streaming**: Real-time response streaming
- **Structured Generation**: Type-safe data with `@Generable`
- **Generation Guides**: Constrained outputs with `@Guide`
- **Tool Calling**: System integrations for extended functionality
- **RAG**: Document indexing and semantic search with LumoKit/VecturaKit
- **Voice**: Speech-to-text and text-to-speech
- **Health**: HealthKit integration with AI insights
- **Multilingual**: Works in 10 languages (English, German, Spanish, French, Italian, Japanese, Korean, Portuguese, Chinese)

### Dynamic Schemas
The app includes 11 dynamic schema examples ranging from basic to expert:
- Basic schemas
- Arrays and collections
- Enums and union types
- Nested objects
- Schema references
- Form builders
- Invoice processing
- Error handling patterns

### Playground Examples
Four chapters with hands-on examples:
- **Chapter 2**: Getting Started with Sessions (16 examples)
- **Chapter 3**: Generation Options and Sampling Control (5 examples)
- **Chapter 8**: Basic Tool Use (9 examples)
- **Chapter 13**: Languages and Internationalization (7 examples)

Run these directly in Xcode using the `#Playground` directive.

## Usage Examples

### Basic Chat
```swift
let session = LanguageModelSession()
let response = try await session.respond(
    to: "Suggest a catchy name for a new coffee shop."
)
print(response.content)
```

### Structured Data Generation
```swift
let session = LanguageModelSession()
let bookInfo = try await session.respond(
    to: "Suggest a sci-fi book.",
    generating: BookRecommendation.self
)
print("Title: \(bookInfo.content.title)")
print("Author: \(bookInfo.content.author)")
```

### Tool Calling
```swift
// Single tool
let weatherSession = LanguageModelSession(tools: [WeatherTool()])
let response = try await weatherSession.respond(
    to: "Is it hotter in New Delhi or Cupertino?"
)

// Multiple tools
let multiSession = LanguageModelSession(tools: [
    WeatherTool(),
    Search1WebSearchTool(),
    ContactsTool()
])
let multiResponse = try await multiSession.respond(
    to: "Check the weather, search the web, and find my friend John's contact"
)
```

### Streaming Responses
```swift
let session = LanguageModelSession()
let stream = session.streamResponse(to: "Write a short poem about technology.")

for try await partialText in stream {
    print("Partial: \(partialText)")
}
```

### Voice Interface
```swift
// Speech recognition
let recognizer = SpeechRecognizer()
try recognizer.startRecognition()

// Text-to-speech
try await SpeechSynthesizer.shared.synthesizeAndSpeak(text: "Hello, how can I help you?")
```

### Health Data
```swift
let session = LanguageModelSession(tools: [HealthDataTool()])
let response = try await session.respond(
    to: "Show me my step count trends this week"
)
```

## Data Models

The app includes various `@Generable` data models for different use cases:

### General Purpose
```swift
@Generable
struct BookRecommendation {
    @Guide(description: "The title of the book")
    let title: String

    @Guide(description: "The author's name")
    let author: String

    @Guide(description: "Genre of the book")
    let genre: Genre
}

@Generable
struct ProductReview {
    @Guide(description: "Product name")
    let productName: String

    @Guide(description: "Rating from 1 to 5")
    let rating: Int

    @Guide(description: "Key pros and cons")
    let pros: [String]
    let cons: [String]
}

@Generable
struct StoryOutline {
    let title: String
    let protagonist: String
    let conflict: String
    let setting: String
    let genre: StoryGenre
    let themes: [String]
}

@Generable
struct JournalEntrySummary {
    let prompt: String
    let upliftingMessage: String
    let sentenceStarters: [String]
    let summaryBullets: [String]
    let themes: [String]
}
```

### Health Models
```swift
@Generable
struct HealthAI {
    let greeting: String
    let mood: HealthAIMood
    let motivationalMessage: String
    let focusMetrics: [String]
    let suggestions: [String]
}

@Generable
struct HealthAnalysis {
    let healthScore: Int
    let trends: HealthTrends
    let insights: [HealthInsightDetail]
    let correlations: [MetricCorrelation]
    let predictions: [HealthPrediction]
    let recommendations: [String]
}

@Generable
struct PersonalizedHealthPlan {
    let title: String
    let overview: String
    let currentStatus: String
    let weeklyActivities: [String]
    let nutritionGuidelines: NutritionPlan
    let sleepStrategy: String
    let milestones: [String]
}
```

### Chat Context
```swift
@Generable
struct ConversationSummary {
    let summary: String
    let keyTopics: [String]
    let userPreferences: [String]
}
```

## Tools Details

### Weather Tool
- Uses OpenMeteo API for real-time weather
- Temperature, humidity, wind speed, conditions
- Automatic geocoding
- No API key required

### Web Search Tool
- Uses Search1API keyless endpoint
- Returns search results with snippets
- No API key required (free tier limits)

### Contacts Tool
- Search system contacts
- Natural language queries
- Requires contacts permission

### Calendar Tool
- Create and manage events
- Timezone and locale aware
- Supports relative dates ("today", "tomorrow")
- Requires calendar permission

### Reminders Tool
- Create reminders with AI
- Priority levels: None, Low, Medium, High
- Due dates and notes
- Requires reminders permission

### Location Tool
- Current location information
- Geocoding support
- Requires location permission

### Health Tool
- HealthKit integration
- Query health metrics
- AI-powered insights
- Requires HealthKit permission

### Music Tool
- Apple Music search
- Songs, artists, albums
- Requires Apple Music subscription
- Requires music permission

### Web Metadata Tool
- Extract webpage metadata
- Generate social media summaries
- Platform-specific formatting
- No API key required

## Multilingual Support

The app works in 10 languages:
- English
- German
- Spanish
- French
- Italian
- Japanese
- Korean
- Portuguese (Brazil)
- Chinese (Simplified)
- Chinese (Traditional)

Language detection and code-switching examples are included in the Integrations section.

## Permissions

The app may request the following permissions depending on which features you use:
- Microphone (for voice input)
- Speech Recognition
- Contacts
- Calendar
- Reminders
- Location
- HealthKit
- Apple Music

All permissions are requested at the appropriate time and can be managed in Settings.

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

[![Star History Chart](https://api.star-history.com/svg?repos=rudrankriyam/Foundation-Models-Framework-Lab&type=Date)](https://star-history.com/#rudrankriyam/Foundation-Models-Framework-Lab&Date)
