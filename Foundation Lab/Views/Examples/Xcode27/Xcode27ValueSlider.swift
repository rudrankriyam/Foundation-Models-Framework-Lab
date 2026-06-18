//
//  Xcode27ValueSlider.swift
//  FoundationLab
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

struct Xcode27ValueSlider: View {
    let title: String
    let valueText: String
    let systemImage: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    var step = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            LabeledContent {
                Text(valueText)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            } label: {
                Label(title, systemImage: systemImage)
            }

            Slider(value: $value, in: range, step: step)
                .accessibilityLabel(title)
                .accessibilityValue(valueText)
        }
    }
}
