//
//  ExpertWorkspace.swift
//  Foundation Lab
//

import Foundation

enum ExpertWorkspace: String, Hashable, Identifiable {
    case adapterComparison
    case appBench

    var id: Self { self }

    var title: String {
        switch self {
        case .adapterComparison:
            String(localized: "Adapter Comparison")
        case .appBench:
            String(localized: "AppBench")
        }
    }

    var summary: String {
        switch self {
        case .adapterComparison:
            String(localized: "Compare a custom .fmadapter package with the base system model.")
        case .appBench:
            String(localized: "Run repeatable app-shaped quality and performance evaluations.")
        }
    }

    var systemImage: String {
        switch self {
        case .adapterComparison:
            "square.split.2x1"
        case .appBench:
            "gauge.with.dots.needle.67percent"
        }
    }
}
