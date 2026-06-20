//
//  TokenUsageBar.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 2/17/26.
//

import SwiftUI

struct TokenUsageBar: View {
    let currentTokenCount: Int
    let maxContextSize: Int
    let tokenUsageFraction: Double

    var body: some View {
        if currentTokenCount > 0 {
            VStack(spacing: 2) {
                ProgressView(value: tokenUsageFraction)
                    .tint(tokenUsageColor)

                HStack {
                    Text("\(currentTokenCount) / \(maxContextSize) tokens")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(tokenUsageFraction * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 4)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: currentTokenCount)
        }
    }

    private var tokenUsageColor: Color {
        switch tokenUsageFraction {
        case 0..<0.5:
            return .green
        case 0.5..<0.75:
            return .yellow
        case 0.75..<0.9:
            return .orange
        default:
            return .red
        }
    }
}
