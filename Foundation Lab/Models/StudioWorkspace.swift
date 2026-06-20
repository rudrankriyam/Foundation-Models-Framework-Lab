//
//  StudioWorkspace.swift
//  Foundation Lab
//
//  Created by Codex on 5/23/26.
//

import Foundation
import FoundationLabCore

enum StudioWorkspace: String, CaseIterable, Identifiable {
    case promptTesting
    case adapterComparison
    case benchmarkRuns

    var id: Self { self }

    var title: String {
        switch self {
        case .promptTesting:
            return "Prompt Testing"
        case .adapterComparison:
            return "Adapter Comparison"
        case .benchmarkRuns:
            return "Benchmark Runs"
        }
    }

    var subtitle: String {
        switch self {
        case .promptTesting:
            return "Compare instructions, sampling, and prompt variants."
        case .adapterComparison:
            return "Compare a custom .fmadapter package with the base system model."
        case .benchmarkRuns:
            return "Compare app-shaped workloads with separate quality and performance metrics."
        }
    }

    var icon: String {
        switch self {
        case .promptTesting:
            return "text.bubble"
        case .adapterComparison:
            return "square.split.2x1"
        case .benchmarkRuns:
            return "speedometer"
        }
    }

    var status: String {
        switch self {
        case .promptTesting:
            return "Interactive"
        case .adapterComparison:
            return "Available"
        case .benchmarkRuns:
            return "CLI Workflow"
        }
    }
}

enum StudioPipelineStage: String, CaseIterable, Identifiable {
    case settings
    case runs
    case evaluation
    case preview
    case output

    var id: Self { self }

    var title: String {
        switch self {
        case .settings:
            return "Settings"
        case .runs:
            return "Runs"
        case .evaluation:
            return "Evaluation"
        case .preview:
            return "Preview"
        case .output:
            return "Output"
        }
    }

    var systemImage: String {
        switch self {
        case .settings:
            return "slider.horizontal.3"
        case .runs:
            return "play.circle"
        case .evaluation:
            return "chart.bar.doc.horizontal"
        case .preview:
            return "eye"
        case .output:
            return "square.and.arrow.up"
        }
    }
}

struct StudioActivityEvent: Identifiable {
    let id: String
    let title: String
    let detail: String
    let date: Date
}

enum StudioPromptVariant: String, CaseIterable, Identifiable {
    case baseline
    case concise
    case structured
    case productTone

    var id: Self { self }

    var title: String {
        switch self {
        case .baseline:
            return "Baseline"
        case .concise:
            return "Concise"
        case .structured:
            return "Structured"
        case .productTone:
            return "Product Tone"
        }
    }

    var subtitle: String {
        switch self {
        case .baseline:
            return "Plain prompt with default instructions."
        case .concise:
            return "Short, direct answer with low temperature."
        case .structured:
            return "Answer with a summary and validation notes."
        case .productTone:
            return "Useful answer written like a developer tool."
        }
    }

    var systemPrompt: String? {
        switch self {
        case .baseline:
            return nil
        case .concise:
            return "Answer directly. Prefer concrete wording and avoid filler."
        case .structured:
            return "Return a clear answer with sections: Summary, Details, and Validation Notes."
        case .productTone:
            return "You are helping an Apple platforms developer evaluate local Foundation Models behavior. "
                + "Be practical, specific, and product-minded."
        }
    }

    var generationOptions: FoundationLabGenerationOptions {
        switch self {
        case .baseline:
            return FoundationLabGenerationOptions(maximumResponseTokens: 260)
        case .concise:
            return FoundationLabGenerationOptions(
                sampling: .greedy,
                temperature: 0.2,
                maximumResponseTokens: 180
            )
        case .structured:
            return FoundationLabGenerationOptions(
                sampling: .randomProbabilityThreshold(0.85),
                temperature: 0.5,
                maximumResponseTokens: 360
            )
        case .productTone:
            return FoundationLabGenerationOptions(
                sampling: .randomTop(40),
                temperature: 0.7,
                maximumResponseTokens: 320
            )
        }
    }
}

struct StudioPromptRun: Identifiable, Hashable {
    let id = UUID()
    let variant: StudioPromptVariant
    let prompt: String
    let output: String
    let duration: TimeInterval
    let tokenCount: Int?
    let finishedAt: Date

    var durationLabel: String {
        duration.formatted(.number.precision(.fractionLength(2))) + "s"
    }

    var tokenLabel: String {
        guard let tokenCount else { return "No token count" }
        return "\(tokenCount) tokens"
    }
}
