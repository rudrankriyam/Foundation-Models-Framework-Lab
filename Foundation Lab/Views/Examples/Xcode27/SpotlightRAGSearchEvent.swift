//
//  SpotlightRAGSearchEvent.swift
//  FoundationLab
//

import Foundation

struct SpotlightRAGSearchEvent: Identifiable, Sendable {
    enum Kind: String, Sendable {
        case items
        case scoredItems
        case groupedItems
        case count
        case table
        case statistic
        case text

        var systemImage: String {
            switch self {
            case .items, .scoredItems: "doc.text.magnifyingglass"
            case .groupedItems: "square.stack.3d.up"
            case .count: "number"
            case .table: "tablecells"
            case .statistic: "chart.bar"
            case .text: "text.quote"
            }
        }
    }

    let id = UUID()
    let queryNumber: Int
    let label: String
    let detail: String
    let kind: Kind
    let isComplete: Bool
}
