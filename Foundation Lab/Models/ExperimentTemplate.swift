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
    case workflows

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
            return String(localized: "Projects")
        case .workflows:
            return String(localized: "Workflows")
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
        case .workflows:
            return String(localized: "Combine tools, inspect behavior, and measure results.")
        }
    }

    var systemImage: String {
        switch self {
        case .startHere:
            "sparkles"
        case .buildWithTools:
            "wrench.and.screwdriver"
        case .structuredOutput:
            "curlybraces.square"
        case .contextAndRuntime:
            "cpu"
        case .appliedProjects:
            "shippingbox"
        case .workflows:
            "point.topleft.down.curvedto.point.bottomright.up"
        }
    }
}

enum ExperimentLibraryCatalog: String, Hashable, Identifiable {
    case schemas
    case languages
    case xcode27

    var id: String { rawValue }

    var title: String {
        switch self {
        case .schemas:
            return String(localized: "Dynamic Schemas")
        case .languages:
            return String(localized: "Languages")
        case .xcode27:
            return String(localized: "Xcode 27")
        }
    }
}

enum ExperimentLaunch: Hashable {
    case recipe(FoundationLabExperimentConfiguration)
    case guidedLab(ExampleType)
    case workshop(ExperimentLibraryCatalog)
    case workspace(Workspace)

    var displayName: String {
        switch self {
        case .recipe:
            String(localized: "Recipe")
        case .guidedLab:
            String(localized: "Guided Lab")
        case .workshop:
            String(localized: "Workshop")
        case .workspace:
            String(localized: "Workspace")
        }
    }

    var systemImage: String {
        switch self {
        case .recipe:
            "slider.horizontal.3"
        case .guidedLab:
            "book.pages"
        case .workshop:
            "square.grid.2x2"
        case .workspace:
            "macwindow.and.cursorarrow"
        }
    }
}

struct ExperimentTemplate: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let systemImage: String
    let track: ExperimentTrack
    let launch: ExperimentLaunch
    let keywords: [String]

    init(
        id: String,
        title: String,
        summary: String,
        systemImage: String,
        track: ExperimentTrack,
        launch: ExperimentLaunch,
        keywords: [String] = []
    ) {
        self.id = id
        self.title = String(localized: String.LocalizationValue(title))
        self.summary = String(localized: String.LocalizationValue(summary))
        self.systemImage = systemImage
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
        + workflowTemplates

    static func templates(in track: ExperimentTrack) -> [ExperimentTemplate] {
        curatedLibrary.filter { $0.track == track }
    }

    private static let startHereTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "blank-playground",
            title: "New Experiment",
            summary: "Start with a blank prompt and configure the model yourself.",
            systemImage: "plus.square",
            track: .startHere,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: ""
                ))
            ),
            keywords: ["blank", "custom", "prompt"]
        ),
        ExperimentTemplate(
            id: "one-shot",
            title: "One-Shot Prompt",
            summary: "Send one prompt and inspect one complete response.",
            systemImage: "ellipsis.message",
            track: .startHere,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "One-Shot Prompt",
                    summary: "Send one prompt and inspect the complete response",
                    prompt: "Explain why on-device language models are useful in an iOS app.",
                    instructions: "Answer clearly in three short paragraphs and include one concrete example.",
                    kind: .generation
                ))
            ),
            keywords: ["basic", "prompt", "first response"]
        ),
        ExperimentTemplate(
            id: "streaming",
            title: "Streaming Response",
            summary: "Watch the response arrive as the model generates it.",
            systemImage: "text.line.first.and.arrowtriangle.forward",
            track: .startHere,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Streaming Response",
                    summary: "Watch the response arrive as the model generates it",
                    prompt: "Write a short field guide for observing the night sky from a city balcony.",
                    instructions: "Use a brief introduction followed by five practical tips.",
                    kind: .generation,
                    generationOptions: FoundationLabGenerationOptions(maximumResponseTokens: 320)
                ))
            ),
            keywords: ["stream", "incremental", "live response"]
        ),
        ExperimentTemplate(
            id: "guided-conversation",
            title: "Guided Conversation",
            summary: "See how editable instructions shape a model response.",
            systemImage: "bubble.left.and.text.bubble.right",
            track: .startHere,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Guided Conversation",
                    summary: "Learn how instructions shape a response",
                    prompt: "Explain on-device language models using a simple analogy.",
                    instructions: "Be concise, friendly, and define technical terms the first time you use them.",
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
            summary: "Start with two tools, customize the configuration, and generate reusable Swift code.",
            systemImage: "wrench.and.screwdriver",
            track: .buildWithTools,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Tool-Enabled Assistant",
                    summary: "A customizable assistant grounded in current tool results",
                    prompt: "Compare today's weather in Cupertino with a good indoor alternative nearby.",
                    instructions: "Use tools when they provide fresher or more reliable information. Explain which evidence you used.",
                    kind: .toolUse,
                    selectedTools: [.weather, .web]
                ))
            ),
            keywords: ["agent", "custom", "composer", "multiple tools"]
        )
    ] + FoundationLabBuiltInTool.allCases.map { tool in
        ExperimentTemplate(
            id: "tool-\(tool.rawValue)",
            title: tool.displayName,
            summary: toolLibrarySummary(tool),
            systemImage: tool.systemImage,
            track: .buildWithTools,
            launch: .recipe(toolRecipeConfiguration(tool)),
            keywords: ["tool calling", "system integration", tool.summary]
        )
    }

    private static let structuredOutputTemplates: [ExperimentTemplate] = [
        template(
            .structuredData,
            id: "structured-data",
            track: .structuredOutput,
            summary: "Generate type-safe Swift values instead of parsing prose."
        ),
        template(
            .generationGuides,
            id: "generation-guides",
            track: .structuredOutput,
            summary: "Constrain generated properties with clear, testable guides."
        ),
        ExperimentTemplate(
            id: "dynamic-schema-catalog",
            title: "Dynamic Schema Workshop",
            summary: "Progress from a basic object to forms, unions, and invoice extraction.",
            systemImage: "curlybraces.square",
            track: .structuredOutput,
            launch: .workshop(.schemas),
            keywords: ["schema", "generable", "json", "invoice", "form"]
        )
    ]

    private static let contextTemplates: [ExperimentTemplate] = [
        template(
            .modelAvailability,
            id: "model-availability",
            track: .contextAndRuntime,
            summary: "Check whether the system model is ready before starting work."
        ),
        ExperimentTemplate(
            id: "generation-options",
            title: "Generation Options",
            summary: "Tune sampling and response limits, then compare the output.",
            systemImage: "slider.horizontal.3",
            track: .contextAndRuntime,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Generation Options",
                    summary: "Compare a deliberate sampling setup with the defaults",
                    prompt: "Propose three names for a privacy-first journaling app and explain the strongest choice.",
                    instructions: "Keep each name distinctive and make the comparison concrete.",
                    kind: .generation,
                    generationOptions: FoundationLabGenerationOptions(
                        sampling: .randomTop(40, seed: 42),
                        temperature: 0.7,
                        maximumResponseTokens: 320
                    )
                ))
            ),
            keywords: ["sampling", "temperature", "tokens", "seed"]
        )
    ]

    private static let appliedTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "journaling",
            title: "Journaling",
            summary: "Turn free-form reflections into thoughtful prompts and summaries.",
            systemImage: "book.closed",
            track: .appliedProjects,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Journaling",
                    summary: "Transform a reflection into a useful, compassionate summary",
                    prompt: "I felt scattered this morning, but a quiet walk helped me focus on the work that matters.",
                    instructions: "Summarize the reflection without diagnosing. Then offer one gentle follow-up question.",
                    kind: .applied,
                    generationOptions: FoundationLabGenerationOptions(maximumResponseTokens: 220)
                ))
            ),
            keywords: ["reflection", "summary", "writing"]
        ),
        ExperimentTemplate(
            id: "creative-writing",
            title: "Creative Writing",
            summary: "Explore how prompt changes shape creative output.",
            systemImage: "pencil.and.outline",
            track: .appliedProjects,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Creative Writing",
                    summary: "Experiment with voice, constraints, and revision",
                    prompt: "Write a scene about a lighthouse keeper receiving an impossible weather report.",
                    instructions: "Use vivid but economical prose, no more than 350 words, and end on an unresolved image.",
                    kind: .generation,
                    generationOptions: FoundationLabGenerationOptions(
                        temperature: 0.9,
                        maximumResponseTokens: 520
                    )
                ))
            ),
            keywords: ["story", "creative", "revision", "constraints"]
        ),
        template(
            .rag,
            id: "document-question-answering",
            track: .appliedProjects,
            summary: "Index documents and ask grounded questions with source citations."
        ),
        template(
            .health,
            id: "health-dashboard",
            track: .appliedProjects,
            summary: "Review authorized HealthKit data and ask grounded questions."
        ),
        ExperimentTemplate(
            id: "language-catalog",
            title: "Multilingual Workshop",
            summary: "Check language support, generate localized responses, and manage sessions.",
            systemImage: "character.book.closed",
            track: .appliedProjects,
            launch: .workshop(.languages),
            keywords: ["languages", "localization", "translation", "multilingual"]
        )
    ]

    private static let workflowTemplates: [ExperimentTemplate] = [
        ExperimentTemplate(
            id: "agent-workbench",
            title: "Agent Workbench",
            summary: "Configure a multi-tool workflow, inspect each run, and generate Swift code.",
            systemImage: "point.topleft.down.curvedto.point.bottomright.up",
            track: .workflows,
            launch: .recipe(
                localizedConfiguration(FoundationLabExperimentConfiguration(
                    name: "Agent Workbench",
                    summary: "Configure a multi-tool workflow, inspect each run, and generate Swift code.",
                    prompt: "Plan a focused afternoon around my next calendar event and create any useful follow-up reminder.",
                    instructions: "Use the minimum number of tools needed. Ask before making changes and summarize every side effect.",
                    kind: .toolUse,
                    selectedTools: [.calendar, .reminders, .location]
                ))
            ),
            keywords: ["agent", "custom tools", "workflow", "permissions"]
        ),
        ExperimentTemplate(
            id: "xcode-27",
            title: "Xcode 27",
            summary: "Build and measure experiments with the Xcode 27 SDK.",
            systemImage: "apple.intelligence",
            track: .workflows,
            launch: .workshop(.xcode27),
            keywords: ExampleType.xcode27Examples.flatMap { [$0.title, $0.subtitle] }
        ),
        ExperimentTemplate(
            id: "adapter-comparison",
            title: "Adapter Comparison",
            summary: "Compare a custom .fmadapter package with the base model in fresh sessions.",
            systemImage: "square.split.2x1",
            track: .workflows,
            launch: .workspace(.adapterComparison),
            keywords: ["adapter", "fmadapter", "fine tuning", "comparison", "fmas"]
        ),
        ExperimentTemplate(
            id: "fmfbench",
            title: "FMFBench",
            summary: "Run repeatable quality and performance evaluations based on real app tasks.",
            systemImage: "gauge.with.dots.needle.67percent",
            track: .workflows,
            launch: .workspace(.fmfBench),
            keywords: ["benchmark", "evaluation", "latency", "quality", "device runner"]
        )
    ]

    private static func template(
        _ example: ExampleType,
        id: String,
        track: ExperimentTrack,
        summary: String
    ) -> ExperimentTemplate {
        ExperimentTemplate(
            id: id,
            title: example.title,
            summary: summary,
            systemImage: example.icon,
            track: track,
            launch: .guidedLab(example),
            keywords: [example.subtitle]
        )
    }

}
