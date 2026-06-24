//
//  Workspace.swift
//  Foundation Lab
//

import Foundation

enum Workspace: String, Hashable, Identifiable {
    case adapterComparison
    case fmfBench

    var id: Self { self }

    var title: String {
        switch self {
        case .adapterComparison:
            String(localized: "Adapter Comparison")
        case .fmfBench:
            String(localized: "FMFBench")
        }
    }

    var summary: String {
        switch self {
        case .adapterComparison:
            String(localized: "Compare a custom .fmadapter package with the base system model.")
        case .fmfBench:
            String(localized: "Run repeatable app-shaped quality and performance evaluations.")
        }
    }

    var systemImage: String {
        switch self {
        case .adapterComparison:
            "square.split.2x1"
        case .fmfBench:
            "gauge.with.dots.needle.67percent"
        }
    }

    func title(for stage: WorkspaceStage) -> String {
        switch (self, stage) {
        case (.adapterComparison, .settings):
            String(localized: "Setup")
        case (.adapterComparison, .runs):
            String(localized: "Compare")
        case (.adapterComparison, .evaluation):
            String(localized: "Metrics")
        case (.adapterComparison, .preview):
            String(localized: "Workflow")
        case (.adapterComparison, .output):
            String(localized: "Results")
        case (.fmfBench, .settings):
            String(localized: "Protocol")
        case (.fmfBench, .runs):
            String(localized: "Run")
        case (.fmfBench, .evaluation):
            String(localized: "Evaluate")
        case (.fmfBench, .preview):
            String(localized: "Suites")
        case (.fmfBench, .output):
            String(localized: "Artifacts")
        }
    }

    func systemImage(for stage: WorkspaceStage) -> String {
        switch stage {
        case .settings:
            "slider.horizontal.3"
        case .runs:
            "play.circle"
        case .evaluation:
            "chart.bar.doc.horizontal"
        case .preview:
            "list.bullet.rectangle"
        case .output:
            "doc.text"
        }
    }
}
