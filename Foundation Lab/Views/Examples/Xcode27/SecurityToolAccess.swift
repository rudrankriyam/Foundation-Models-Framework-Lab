//
//  SecurityToolAccess.swift
//  FoundationLab
//

import Foundation

enum SecurityToolAccess: String, CaseIterable, Identifiable {
    case none
    case readOnly
    case sideEffect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: String(localized: "No tools")
        case .readOnly: String(localized: "Read-only search")
        case .sideEffect: String(localized: "External message")
        }
    }

    var detail: String {
        switch self {
        case .none: String(localized: "The session receives no tool definitions.")
        case .readOnly: String(localized: "The model may request data, but the tool does not change external state.")
        case .sideEffect: String(localized: "The model may propose a message; app code owns validation and authorization.")
        }
    }

    var hasSideEffect: Bool { self == .sideEffect }
}
