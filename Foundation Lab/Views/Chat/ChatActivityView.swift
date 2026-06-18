//
//  ChatActivityView.swift
//  FoundationLab
//

import SwiftUI

struct ChatActivityView: View {
    let title: LocalizedStringKey

    var body: some View {
        HStack {
            ProgressView()
                .controlSize(.small)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }
}
