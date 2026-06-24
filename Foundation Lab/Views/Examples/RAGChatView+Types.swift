//
//  RAGChatView+Types.swift
//  FoundationLab
//
//  Supporting types for RAG chat functionality.
//

import Foundation
import SwiftUI

// MARK: - RAG Chunk

struct RAGChunk {
    let documentId: String
    let documentTitle: String
    let content: String
    let chunkIndex: Int
    let similarityScore: Double
}

// MARK: - Source Card

struct RAGSourceCard: View {
    let index: Int
    let source: RAGChunk

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: "\(min(index, 50)).circle.fill")
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(source.documentTitle)
                    .font(.subheadline.weight(.semibold))

                Text(source.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Source \(index): \(source.documentTitle). \(source.content)")
    }
}
