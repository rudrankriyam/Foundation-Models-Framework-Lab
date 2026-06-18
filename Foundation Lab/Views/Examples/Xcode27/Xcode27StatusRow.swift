//
//  Xcode27StatusRow.swift
//  FoundationLab
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

struct Xcode27StatusRow: View {
    let title: String
    let value: String
    let systemImage: String
    var tint: Color = .blue

    var body: some View {
        LabeledContent {
            Text(value)
                .font(.headline)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        } label: {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }
}
