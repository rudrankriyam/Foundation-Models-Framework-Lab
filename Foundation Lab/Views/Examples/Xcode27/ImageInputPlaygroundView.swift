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
            title: "Image Input Reference",
            description: "Inspect image attachment recipes and measured resolution boundaries",
            codeExample: selectedRecipe.code,
            referenceNote: """
            Choose a recipe to update the sample prompt and code. No image is attached and no model request is sent on this page.
            """
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Attachment Flow") {
                    VStack(alignment: .leading, spacing: 0) {
                        Xcode27InfoRow(
                            title: "Attach an image",
                            detail: """
                            Create Attachment<ImageAttachmentContent> from a CGImage, CIImage, pixel buffer, or image URL. On supported \
                            platforms, UIImage and NSImage also work.
                            """,
                            systemImage: "1.circle"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: "Label it",
                            detail: """
                            Use a short label so generated ImageReference values can resolve back to the right transcript attachment.
                            """,
                            systemImage: "2.circle"
                        )
                        .padding(.vertical, Spacing.small)

                        Divider()

                        Xcode27InfoRow(
                            title: "Resolve references",
                            detail: "Generated ImageReference can resolve in the transcript, which is useful for multimodal follow-ups.",
                            systemImage: "3.circle"
                        )
                        .padding(.vertical, Spacing.small)
                    }
                }

                ImageInputResolutionFindingsView()

                Xcode27Section("Recipes") {
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

                Xcode27Section("Response focus") {
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
            return "Alt Text"
        case .screenshotBug:
            return "Bug Report"
        case .uiAudit:
            return "UI Audit"
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
            return "Ask for a compact description suitable for accessibility labels and summaries."
        case .screenshotBug:
            return "Ask for a title, observed behavior, expected behavior, visible evidence, and reproduction hints."
        case .uiAudit:
            return "Ask the model to inspect layout, hierarchy, contrast, spacing, text clipping, and actionable fixes."
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
