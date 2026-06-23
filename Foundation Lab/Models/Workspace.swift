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
}
