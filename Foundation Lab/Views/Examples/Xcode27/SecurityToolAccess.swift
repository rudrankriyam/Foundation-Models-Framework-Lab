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
        case .none: "No tools"
        case .readOnly: "Read-only search"
        case .sideEffect: "External message"
        }
    }

    var detail: String {
        switch self {
        case .none: "The session receives no tool definitions."
        case .readOnly: "The model may request data, but the tool does not change external state."
        case .sideEffect: "The model may propose a message; app code owns validation and authorization."
        }
    }

    var hasSideEffect: Bool { self == .sideEffect }
}
