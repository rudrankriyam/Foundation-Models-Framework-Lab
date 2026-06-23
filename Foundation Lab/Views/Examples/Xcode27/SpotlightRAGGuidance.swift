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
}
