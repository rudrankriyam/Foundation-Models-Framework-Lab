//
//  Xcode27InfoRow.swift
//  FoundationLab
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

struct Xcode27InfoRow: View {
    let title: String
    let detail: String
    let systemImage: String
    var tint: Color = .blue

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(.subheadline)
                    .bold()

                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
