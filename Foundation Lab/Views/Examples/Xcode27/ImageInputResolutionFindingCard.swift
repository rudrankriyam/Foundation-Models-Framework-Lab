//
//  ImageInputResolutionFindingCard.swift
//  FoundationLab
//
//  Created by Codex on 6/14/26.
//

import SwiftUI

struct ImageInputResolutionFindingCard: View {
    let ratio: String
    let largestCorrect: String
    let firstIncorrect: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(ratio)
                .font(.headline)

            VStack(alignment: .leading, spacing: 4) {
                Label("Largest correct", systemImage: "checkmark.circle.fill")
                    .font(.footnote)
                    .foregroundStyle(.green)

                Text(largestCorrect)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }

            VStack(alignment: .leading, spacing: 4) {
                Label("First incorrect", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(.orange)

                Text(firstIncorrect)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }
}
