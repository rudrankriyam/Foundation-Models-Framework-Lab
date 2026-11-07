//
//  ColorSwatchStrip.swift
//  FoundationLab
//

import SwiftUI

struct ColorSwatchStrip: View {
    let swatch: ColorSwatch

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            HStack(spacing: Spacing.xSmall) {
                ForEach(swatch.colors.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: CornerRadius.small)
                        .fill(color(swatch.colors[index]))
                        .frame(height: FoundationLabLayout.minimumTouchTarget)
                }
            }
            Text(swatch.hexValues)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(swatch.name): \(swatch.hexValues)"))
    }

    private func color(_ rgb: UInt32) -> Color {
        Color(
            red: Double(rgb >> 16 & 0xFF) / 255,
            green: Double(rgb >> 8 & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}
