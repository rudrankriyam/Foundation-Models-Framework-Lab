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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: Spacing.small) {
                Text("[\(index)]")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text(source.documentTitle)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Text(source.content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.small)
        .background(Color.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
