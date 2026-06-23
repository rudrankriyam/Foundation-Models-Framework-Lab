//
//  SpotlightRAGUnavailableView.swift
//  FoundationLab
//

import SwiftUI

struct SpotlightRAGUnavailableView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Spotlight RAG Unavailable", systemImage: "magnifyingglass.circle")
        } description: {
            Text(message)
        }
        .navigationTitle("Spotlight RAG")
    }
}
