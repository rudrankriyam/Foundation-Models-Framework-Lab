//
//  DataModels.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import Foundation
import FoundationModels

// MARK: - Chat Models

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let entryID: Transcript.Entry.ID?
    let content: AttributedString
    let isFromUser: Bool
    let timestamp: Date
    let isContextSummary: Bool

    init(content: String, isFromUser: Bool, isContextSummary: Bool = false) {
        self.init(entryID: nil, content: content, isFromUser: isFromUser, isContextSummary: isContextSummary)
    }

    init(entryID: Transcript.Entry.ID?, content: String, isFromUser: Bool, isContextSummary: Bool = false) {
        self.id = UUID()
        self.entryID = entryID
        self.content = AttributedString(content)
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.isContextSummary = isContextSummary
    }

    init(content: AttributedString, isFromUser: Bool, isContextSummary: Bool = false) {
        self.init(id: UUID(), content: content, isFromUser: isFromUser,
                 timestamp: Date(), isContextSummary: isContextSummary)
    }

    init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false) {
        self.init(id: id, content: AttributedString(content), isFromUser: isFromUser,
                 timestamp: timestamp, isContextSummary: isContextSummary)
    }

    init(id: UUID, content: AttributedString, isFromUser: Bool, timestamp: Date, isContextSummary: Bool = false) {
        self.id = id
        self.entryID = nil
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.isContextSummary = isContextSummary
    }
}
