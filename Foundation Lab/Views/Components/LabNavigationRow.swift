//
//  LabNavigationRow.swift
//  Foundation Lab
//

import SwiftUI

struct LabNavigationRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.xSmall)
        } icon: {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 28)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        LabNavigationRow(
            title: "Private Cloud",
            subtitle: "Probe availability, quota, and context size.",
            systemImage: "icloud.and.arrow.up"
        )
    }
}
