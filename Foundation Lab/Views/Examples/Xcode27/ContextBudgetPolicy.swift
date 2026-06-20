//
//  ContextBudgetPolicy.swift
//  FoundationLab
//

import Foundation

enum ContextBudgetPolicy: String, CaseIterable, Identifiable {
    case preserveAll
    case keepRecent
    case summarizeEarlier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preserveAll: String(localized: "Keep everything")
        case .keepRecent: String(localized: "Keep recent turns")
        case .summarizeEarlier: String(localized: "Summarize earlier turns")
        }
    }

    var systemImage: String {
        switch self {
        case .preserveAll: "text.document"
        case .keepRecent: "clock.arrow.circlepath"
        case .summarizeEarlier: "text.badge.checkmark"
        }
    }

    var explanation: String {
        switch self {
        case .preserveAll:
            String(localized: "Send the transcript unchanged. This is lossless, but it can exceed the model’s context window.")
        case .keepRecent:
            String(localized: "Preserve instructions and the newest conversation entries. Older entries are removed by your app.")
        case .summarizeEarlier:
            String(localized: "Preserve instructions and recent turns, replacing older history with an app-generated summary.")
        }
    }
}
