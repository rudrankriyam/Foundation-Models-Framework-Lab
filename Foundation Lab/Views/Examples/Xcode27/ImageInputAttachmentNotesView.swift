//
//  ImageInputAttachmentNotesView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
struct ImageInputAttachmentNotesView: View {
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup("Attachment API Notes", isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 0) {
                Xcode27InfoRow(
                    title: String(localized: "Attach an image"),
                    detail: String(localized: """
                    Attachment<ImageAttachmentContent> accepts CGImage, CIImage, a pixel buffer, or an image URL.
                    """),
                    systemImage: "1.circle"
                )
                .padding(.vertical, Spacing.small)

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Give it a stable label"),
                    detail: String(localized: """
                    The lab labels the selected input as selected-image so generated ImageReference values can identify it.
                    """),
                    systemImage: "2.circle"
                )
                .padding(.vertical, Spacing.small)

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Inspect the transcript"),
                    detail: String(localized: """
                    Run Evidence counts the attachment segments that Foundation Models records in the live session transcript.
                    """),
                    systemImage: "3.circle"
                )
                .padding(.vertical, Spacing.small)
            }
            .padding(.top, Spacing.small)
        }
        .font(.callout)
    }
}
#endif
