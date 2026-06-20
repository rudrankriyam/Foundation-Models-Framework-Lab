//
//  ImageInputPlaygroundView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ImageInputPlaygroundView: View {
    @State private var selectedRecipe = ImageInputRecipe.altText

    var body: some View {
        ReferenceExampleView(
            title: String(localized: "Image Input Reference"),
            description: String(localized: "Inspect image attachment recipes and measured resolution boundaries"),
            codeExample: selectedRecipe.code,
            referenceNote: String(localized: """
            Choose a recipe to update the sample prompt and code. No image is attached and no model request is sent on this page.
            """)
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section(String(localized: "Attachment Flow")) {
                    VStack(alignment: .leading, spacing: 0) {
                        Xcode27InfoRow(
                            title: String(localized: "Attach an image"),
                            detail: String(localized: """
                            Create Attachment<ImageAttachmentContent> from a CGImage, CIImage, pixel buffer, or image URL. On supported \
                            platforms, UIImage and NSImage also work.
                            """),
                            systemImage: "1.circle"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: String(localized: "Label it"),
                            detail: String(localized: """
                            Use a short label so generated ImageReference values can resolve back to the right transcript attachment.
                            """),
                            systemImage: "2.circle"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: String(localized: "Resolve references"),
                            detail: String(
                                localized: """
                                Generated ImageReference can resolve in the transcript, which is useful for multimodal follow-ups.
                                """
                            ),
                            systemImage: "3.circle"
                        )
                        .padding(.vertical, Spacing.small)
                    }
                }

                ImageInputResolutionFindingsView()

                Xcode27Section(String(localized: "Recipes")) {
                    Picker("Recipe", selection: $selectedRecipe) {
                        ForEach(ImageInputRecipe.allCases) { recipe in
                            Text(recipe.title).tag(recipe)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedRecipe.prompt)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.small)
                }

                Xcode27Section(String(localized: "Response focus")) {
                    Text(selectedRecipe.responseFocus)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private enum ImageInputRecipe: String, CaseIterable, Identifiable {
    case altText
    case screenshotBug
    case uiAudit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .altText:
            return String(localized: "Alt Text")
        case .screenshotBug:
            return String(localized: "Bug Report")
        case .uiAudit:
            return String(localized: "UI Audit")
        }
    }

    var prompt: String {
        switch self {
        case .altText:
            return "Generate concise alt text for this image."
        case .screenshotBug:
            return "Turn this screenshot into a concise bug report."
        case .uiAudit:
            return "Audit this UI screenshot for accessibility and layout issues."
        }
    }

    var responseFocus: String {
        switch self {
        case .altText:
            return String(localized: "Ask for a compact description suitable for accessibility labels and summaries.")
        case .screenshotBug:
            return String(localized: "Ask for a title, observed behavior, expected behavior, visible evidence, and reproduction hints.")
        case .uiAudit:
            return String(localized: "Ask the model to inspect layout, hierarchy, contrast, spacing, text clipping, and actionable fixes.")
        }
    }

    var code: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let image = Attachment<ImageAttachmentContent>(imageURL: imageURL)
                .label("screenshot")

            let session = LanguageModelSession()
            let response = try await session.respond {
                "\(prompt)"
                image
            }
            print(response.content)
        }
        """
    }
}

#Preview {
    NavigationStack {
        ImageInputPlaygroundView()
    }
}
