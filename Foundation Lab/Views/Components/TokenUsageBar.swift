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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if currentTokenCount > 0 {
            VStack(spacing: Spacing.xSmall) {
                ProgressView(value: tokenUsageFraction)
                    .tint(tokenUsageColor)
                    .accessibilityLabel("Context usage")
                    .accessibilityValue(usageAccessibilityValue)

                HStack {
                    Label {
                        Text("\(currentTokenCount) of \(maxContextSize) tokens")
                    } icon: {
                        Image(systemName: usageSystemImage)
                            .foregroundStyle(tokenUsageColor)
                    }

                    Spacer()

                    Text(tokenUsageFraction, format: .percent.precision(.fractionLength(0)))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.small)
            .frame(maxWidth: FoundationLabLayout.transcriptContentWidth)
            .frame(maxWidth: .infinity)
            .background(Color.secondaryBackgroundColor)
            .transition(reduceMotion ? .opacity : .move(edge: .top).combined(with: .opacity))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.2), value: currentTokenCount)
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

    private var usageSystemImage: String {
        switch tokenUsageFraction {
        case 0..<0.75:
            "circle.dotted"
        case 0.75..<0.9:
            "exclamationmark.circle.fill"
        default:
            "exclamationmark.triangle.fill"
        }
    }

    private var usageAccessibilityValue: String {
        let percentage = tokenUsageFraction.formatted(.percent.precision(.fractionLength(0)))
        return String(localized: "\(currentTokenCount) of \(maxContextSize) tokens, \(percentage) used")
    }
}
