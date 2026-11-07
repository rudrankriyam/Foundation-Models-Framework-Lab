//
//  WatchPromptPreset.swift
//  Foundation Lab Watch
//

import Foundation

enum WatchPromptPreset: String, CaseIterable, Identifiable {
    case explainAPI
    case nameIdeas
    case haiku

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explainAPI: String(localized: "Explain an API")
        case .nameIdeas: String(localized: "Name Ideas")
        case .haiku: String(localized: "Haiku")
        }
    }

    var prompt: String {
        switch self {
        case .explainAPI: String(localized: "Explain LanguageModelSession in two sentences.")
        case .nameIdeas: String(localized: "Suggest three names for a running app.")
        case .haiku: String(localized: "Write a haiku about Swift concurrency.")
        }
    }

    var systemImage: String {
        switch self {
        case .explainAPI: "curlybraces"
        case .nameIdeas: "lightbulb"
        case .haiku: "text.quote"
        }
    }
}
