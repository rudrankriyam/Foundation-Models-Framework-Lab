//
//  SpotlightRAGGuidance.swift
//  FoundationLab
//

import Foundation

enum SpotlightRAGGuidance: String, CaseIterable, Identifiable, Sendable {
    case focused
    case dynamic
    case complete

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focused: String(localized: "Focused")
        case .dynamic: String(localized: "Dynamic")
        case .complete: String(localized: "Complete")
        }
    }

    var explanation: String {
        switch self {
        case .focused:
            String(localized: "Focused guidance asks Spotlight for the most relevant matching items.")
        case .dynamic:
            String(localized: "Dynamic guidance lets the model combine keyword, semantic, date, and content-type queries.")
        case .complete:
            String(localized: "Complete guidance exposes every supported Spotlight query field to the model.")
        }
    }
}
