//
//  Workspace.swift
//  Foundation Lab
//

import Foundation

enum Workspace: String, Hashable, Identifiable {
    case adapterComparison

    var id: Self { self }

    var title: String {
        switch self {
        case .adapterComparison:
            String(localized: "Adapter Comparison")
        }
    }

    var summary: String {
        switch self {
        case .adapterComparison:
            String(localized: "Compare a custom .fmadapter package with the base system model.")
        }
    }

    var systemImage: String {
        switch self {
        case .adapterComparison:
            "square.split.2x1"
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
