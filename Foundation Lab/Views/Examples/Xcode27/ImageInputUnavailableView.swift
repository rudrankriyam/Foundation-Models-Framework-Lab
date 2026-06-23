//
//  ImageInputUnavailableView.swift
//  FoundationLab
//

import SwiftUI

struct ImageInputUnavailableView: View {
    let title: String
    let message: String

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                ContentUnavailableView {
                    Label(title, systemImage: "photo.badge.exclamationmark")
                } description: {
                    Text(message)
                }
                .frame(minHeight: 240)

                Text(
                    """
                    The live request is unavailable in this build. You can still inspect the verified attachment shape and measured \
                    resolution notes.
                    """
                )
                    .font(.callout)
                    .foregroundStyle(.secondary)

                ImageInputResolutionFindingsView()
                CodeDisclosure(code: ImageInputRecipe.altText.code)
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Image Input")
        .navigationSubtitle("Attachment reference")
    }
}
