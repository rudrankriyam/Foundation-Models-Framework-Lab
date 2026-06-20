//
//  ExpertWorkspaceStage.swift
//  Foundation Lab
//

import Foundation

enum ExpertWorkspaceStage: String, CaseIterable, Identifiable {
    case settings
    case runs
    case evaluation
    case preview
    case output

    var id: Self { self }

    var title: String {
        switch self {
        case .settings:
            String(localized: "Settings")
        case .runs:
            String(localized: "Runs")
        case .evaluation:
            String(localized: "Evaluation")
        case .preview:
            String(localized: "Preview")
        case .output:
            String(localized: "Output")
        }
    }

    var systemImage: String {
        switch self {
        case .settings:
            "slider.horizontal.3"
        case .runs:
            "play.circle"
        case .evaluation:
            "chart.bar.doc.horizontal"
        case .preview:
            "eye"
        case .output:
            "square.and.arrow.up"
        }
    }
}
