//
//  ExperimentTemplate.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore

enum ExperimentTrack: String, CaseIterable, Hashable, Identifiable {
    case startHere
    case buildWithTools
    case structuredOutput
    case contextAndRuntime
    case appliedProjects
    case advancedWorkflows

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startHere:
            return String(localized: "Start Here")
        case .buildWithTools:
            return String(localized: "Build with Tools")
        case .structuredOutput:
            return String(localized: "Structured Output")
        case .contextAndRuntime:
            return String(localized: "Context & Runtime")
        case .appliedProjects:
            return String(localized: "Applied Projects")
        case .advancedWorkflows:
            return String(localized: "Advanced Workflows")
        }
    }

    var subtitle: String {
        switch self {
        case .startHere:
            return String(localized: "Run a focused example, then change one thing.")
        case .buildWithTools:
            return String(localized: "Connect the model to live system capabilities.")
        case .structuredOutput:
            return String(localized: "Turn responses into reliable, typed data.")
        case .contextAndRuntime:
            return String(localized: "Understand the model, its limits, and each run.")
        case .appliedProjects:
            return String(localized: "Study complete patterns you can adapt to your app.")
        case .advancedWorkflows:
            return String(localized: "Compose and measure production-grade experiments.")
        }
    }
}

enum ExperimentLibraryCatalog: String, Hashable, Identifiable {
    case schemas
    case languages

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schemas:
            return String(localized: "Dynamic Schemas")
        case .languages:
            return String(localized: "Languages")
        }
    }
}

enum ExperimentLaunch: Hashable {
    case playground(FoundationLabExperimentConfiguration)
    case example(ExampleType)
    case tool(ToolExample)
    case catalog(ExperimentLibraryCatalog)
}

struct ExperimentTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let level: FoundationLabExperimentLevel
    let track: ExperimentTrack
    let launch: ExperimentLaunch
    let keywords: [String]

    init(
        id: String,
        title: String,
        summary: String,
        systemImage: String,
        level: FoundationLabExperimentLevel,
        track: ExperimentTrack,
        launch: ExperimentLaunch,
        keywords: [String] = []
    ) {
        self.id = id
        self.title = String(localized: String.LocalizationValue(title))
        self.summary = String(localized: String.LocalizationValue(summary))
        self.systemImage = systemImage
        self.level = level
        self.track = track
        self.launch = launch
        self.keywords = keywords
    }
}

extension ExperimentTemplate {
    static let curatedLibrary: [ExperimentTemplate] =
        startHereTemplates
        + toolTemplates
        + structuredOutputTemplates
        + contextTemplates
        + appliedTemplates
        + advancedTemplates

    static func templates(in track: ExperimentTrack) -> [ExperimentTemplate] {
        curatedLibrary.filter { $0.track == track }
    }

    private static let startHereTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "blank-playground",
            title: "New Experiment",
            summary: "Start with an empty prompt and build at your own pace.",
            systemImage: "plus.square",
            level: .beginner,
            track: .startHere,
            launch: .playground(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: ""
                ))
            ),
            keywords: ["blank", "custom", "prompt"]
        ),
        ExperimentTemplate(
            id: "one-shot",
            title: "One-shot Prompt",
            summary: "Send one prompt and inspect the complete response.",
            systemImage: "ellipsis.message",
            level: .beginner,
            track: .startHere,
            launch: .playground(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "One-shot Prompt",
                    summary: "The shortest path from a prompt to a model response",
                    prompt: "Explain why on-device language models are useful in an iOS app.",
                    instructions: "Answer clearly in three short paragraphs and include one concrete example.",
                    level: .beginner,
                    kind: .generation
                ))
            ),
            keywords: ["basic", "prompt", "first response"]
        ),
        template(
            .streamingResponse,
            id: "streaming",
            level: .beginner,
            track: .startHere,
            summary: "Watch a response arrive incrementally in real time."
        ),
        ExperimentTemplate(
            id: "guided-conversation",
            title: "Guided Conversation",
            summary: "Open a ready-made session with editable instructions and prompt.",
            systemImage: "bubble.left.and.text.bubble.right",
            level: .beginner,
            track: .startHere,
            launch: .playground(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Guided Conversation",
                    summary: "Learn how instructions shape a response",
                    prompt: "Explain on-device language models using a simple analogy.",
                    instructions: "Be concise, friendly, and define technical terms the first time you use them.",
                    level: .beginner,
                    kind: .conversation
                ))
            ),
            keywords: ["instructions", "session", "chat"]
        )
    ]

    private static let toolTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "tool-composer",
            title: "Tool-Enabled Assistant",
            summary: "Fork a two-tool setup, mix in system capabilities, then export the Swift.",
            systemImage: "wrench.and.screwdriver",
            level: .advanced,
            track: .buildWithTools,
            launch: .playground(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Tool-Enabled Assistant",
                    summary: "A customizable assistant grounded by live tools",
                    prompt: "Compare today's weather in Cupertino with a good indoor alternative nearby.",
                    instructions: "Use tools when they provide fresher or more reliable information. Explain which evidence you used.",
                    level: .advanced,
                    kind: .toolUse,
                    selectedTools: [.weather, .web]
                ))
            ),
            keywords: ["agent", "custom", "composer", "multiple tools"]
        )
    ] + ToolExample.allCases.map { tool in
        ExperimentTemplate(
            id: "tool-\(tool.rawValue)",
            title: tool.displayName,
            summary: toolLibrarySummary(tool),
            systemImage: tool.icon,
            level: toolLibraryLevel(tool),
            track: .buildWithTools,
            launch: .tool(tool),
            keywords: ["tool calling", "system integration", tool.shortDescription]
        )
    }

    private static let structuredOutputTemplates: [ExperimentTemplate] = [
        template(
            .structuredData,
            id: "structured-data",
            level: .beginner,
            track: .structuredOutput,
            summary: "Generate type-safe Swift values instead of parsing prose."
        ),
        template(
            .generationGuides,
            id: "generation-guides",
            level: .intermediate,
            track: .structuredOutput,
            summary: "Constrain generated properties with clear, testable guides."
        ),
        ExperimentTemplate(
            id: "dynamic-schema-catalog",
            title: "Dynamic Schema Workshop",
            summary: "Progress from a basic object to forms, unions, and invoice extraction.",
            systemImage: "curlybraces.square",
            level: .advanced,
            track: .structuredOutput,
            launch: .catalog(.schemas),
            keywords: ["schema", "generable", "json", "invoice", "form"]
        )
    ]

    private static let contextTemplates: [ExperimentTemplate] = [
        template(
            .modelAvailability,
            id: "model-availability",
            level: .beginner,
            track: .contextAndRuntime,
            summary: "Check whether the system model is ready before starting work."
        ),
        template(
            .generationOptions,
            id: "generation-options",
            level: .intermediate,
            track: .contextAndRuntime,
            summary: "Tune sampling and response limits, then compare the output."
        ),
        template(
            .modelRuntime,
            id: "model-runtime",
            level: .advanced,
            track: .contextAndRuntime,
            summary: "Inspect the active system model, tokenizer, and capabilities."
        ),
        template(
            .privateCloudCompute,
            id: "private-cloud",
            level: .advanced,
            track: .contextAndRuntime,
            summary: "Probe Private Cloud Compute availability, quota, and context size."
        ),
        template(
            .usagePerformanceTrace,
            id: "usage-trace",
            level: .expert,
            track: .contextAndRuntime,
            summary: "Run a real stream and inspect timing plus reported token usage."
        )
    ]

    private static let appliedTemplates: [ExperimentTemplate] = [
        template(
            .journaling,
            id: "journaling",
            level: .beginner,
            track: .appliedProjects,
            summary: "Turn free-form reflections into thoughtful prompts and summaries."
        ),
        template(
            .creativeWriting,
            id: "creative-writing",
            level: .beginner,
            track: .appliedProjects,
            summary: "Explore how prompt changes shape creative output."
        ),
        template(
            .rag,
            id: "document-question-answering",
            level: .advanced,
            track: .appliedProjects,
            summary: "Index documents and ask grounded questions with source citations."
        ),
        template(
            .health,
            id: "health-dashboard",
            level: .advanced,
            track: .appliedProjects,
            summary: "Study an end-to-end HealthKit experience powered by model tools."
        ),
        ExperimentTemplate(
            id: "language-catalog",
            title: "Multilingual Workshop",
            summary: "Detect support, generate in multiple languages, and manage sessions.",
            systemImage: "character.book.closed",
            level: .intermediate,
            track: .appliedProjects,
            launch: .catalog(.languages),
            keywords: ["languages", "localization", "translation", "multilingual"]
        )
    ]

    private static let advancedTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "agent-workbench",
            title: "Agent Workbench",
            summary: "Tune a multi-tool setup, inspect its runs, and export it as Swift.",
            systemImage: "point.topleft.down.curvedto.point.bottomright.up",
            level: .expert,
            track: .advancedWorkflows,
            launch: .playground(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Agent Workbench",
                    summary: "An expert workspace for composing a multi-tool agent",
                    prompt: "Plan a focused afternoon around my next calendar event and create any useful follow-up reminder.",
                    instructions: "Use the minimum number of tools needed. Ask before making changes and summarize every side effect.",
                    level: .expert,
                    kind: .toolUse,
                    selectedTools: [.calendar, .reminders, .location]
                ))
            ),
            keywords: ["agent", "custom tools", "workflow", "permissions"]
        ),
        template(
            .contextWindowInspector,
            id: "context-window",
            level: .advanced,
            track: .advancedWorkflows,
            summary: "Adjust each context source and learn when to compact a session."
        ),
        template(
            .historyTransformLab,
            id: "history-transforms",
            level: .expert,
            track: .advancedWorkflows,
            summary: "Compare trimming, summarizing, redaction, and spotlighting policies."
        ),
        template(
            .riskyToolConfirmation,
            id: "tool-authorization",
            level: .expert,
            track: .advancedWorkflows,
            summary: "Rehearse app-owned approval before a tool performs a side effect."
        ),
        template(
            .contextBudgetVisualizer,
            id: "context-budget",
            level: .expert,
            track: .advancedWorkflows,
            summary: "Inspect which context is kept, summarized, or dropped as a budget fills."
        ),
        template(
            .foundationModelsSecurityPlayground,
            id: "agent-security",
            level: .expert,
            track: .advancedWorkflows,
            summary: "Exercise framework guarantees and the security boundaries your app owns."
        ),
        template(
            .geminiVideoInput,
            id: "custom-video-model",
            level: .expert,
            track: .advancedWorkflows,
            summary: "Bridge a custom video-capable model into LanguageModelSession."
        )
    ]

    private static func template(
        _ example: ExampleType,
        id: String,
        level: FoundationLabExperimentLevel,
        track: ExperimentTrack,
        summary: String
    ) -> ExperimentTemplate {
        ExperimentTemplate(
            id: id,
            title: example.title,
            summary: summary,
            systemImage: example.icon,
            level: level,
            track: track,
            launch: .example(example),
            keywords: [example.subtitle]
        )
    }

    private static func localizedConfiguration(
        _ configuration: FoundationLabExperimentConfiguration
    ) -> FoundationLabExperimentConfiguration {
        var localized = configuration
        localized.name = String(localized: String.LocalizationValue(configuration.name))
        localized.summary = String(localized: String.LocalizationValue(configuration.summary))
        localized.prompt = String(localized: String.LocalizationValue(configuration.prompt))
        localized.instructions = String(localized: String.LocalizationValue(configuration.instructions))
        return localized
    }

    private static func toolLibrarySummary(_ tool: ToolExample) -> String {
        switch tool {
        case .weather:
            return "Ground an answer in live conditions from Open-Meteo."
        case .web:
            return "Search the web and return current, attributable results."
        case .contacts:
            return "Find people with permission-aware Contacts access."
        case .calendar:
            return "Read and manage events through EventKit."
        case .reminders:
            return "Turn natural-language requests into real reminders."
        case .location:
            return "Resolve the current location for grounded responses."
        case .health:
            return "Query authorized HealthKit data with a focused tool."
        case .music:
            return "Search the Apple Music catalog from a model request."
        case .webMetadata:
            return "Extract useful metadata from a URL for model context."
        }
    }

    private static func toolLibraryLevel(_ tool: ToolExample) -> FoundationLabExperimentLevel {
        switch tool {
        case .weather, .web, .webMetadata:
            return .intermediate
        case .contacts, .calendar, .reminders, .location, .health, .music:
            return .advanced
        }
    }
}
