//
//  LibraryTemplateRow.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct LibraryTemplateRow: View {
    let template: ExperimentTemplate

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: template.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(template.title)
                    .font(.headline)

                Text(template.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(template.title)
        .accessibilityValue(
            "\(template.summary) \(template.launch.displayName)"
        )
    }

}

#Preview {
    List {
        LibraryTemplateRow(template: ExperimentTemplate.curatedLibrary[1])
    }
}
