//
//  ImageInputPlaygroundView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct ImageInputPlaygroundView: View {
    @State private var currentPrompt = "Turn this screenshot into a concise bug report."
    @State private var selectedRecipe = ImageInputRecipe.altText

    var body: some View {
        ExampleViewBase(
            title: "Image Input",
            description: "Explore image attachments, references, and empirical resolution boundaries",
            defaultPrompt: "Turn this screenshot into a concise bug report.",
            currentPrompt: $currentPrompt,
            codeExample: selectedRecipe.code,
            onRun: {},
            onReset: { currentPrompt = "" }
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Attachment Flow", systemImage: "photo.on.rectangle.angled") {
                    VStack(alignment: .leading, spacing: 10) {
                        Xcode27InfoRow(
                            title: "Attach an image",
                            detail: "Create Attachment<ImageAttachmentContent> from a CGImage, CIImage, pixel buffer, image URL, UIImage, or NSImage depending on platform.",
                            systemImage: "1.circle"
                        )

                        Xcode27InfoRow(
                            title: "Label it",
                            detail: "Use a short label so generated ImageReference values can resolve back to the right transcript attachment.",
                            systemImage: "2.circle"
                        )

                        Xcode27InfoRow(
                            title: "Resolve references",
                            detail: "Generated ImageReference can resolve in the transcript, which is useful for multimodal follow-ups.",
                            systemImage: "3.circle"
                        )
                    }
                }

                ImageInputResolutionFindingsView()

                Xcode27Section("Recipes", systemImage: "list.bullet.clipboard") {
                    Picker("Recipe", selection: $selectedRecipe) {
                        ForEach(ImageInputRecipe.allCases) { recipe in
                            Text(recipe.title).tag(recipe)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(selectedRecipe.prompt)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }

                ResultDisplay(
                    result: selectedRecipe.resultPreview,
                    isSuccess: true
                )
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

    var resultPreview: String {
        switch self {
        case .altText:
            return "Example output: A compact description of the image suitable for accessibility labels and summaries."
        case .screenshotBug:
            return "Example output: Title, observed behavior, expected behavior, visible evidence, and repro hints."
        case .uiAudit:
            return "Example output: Layout, hierarchy, contrast, spacing, text clipping, and actionable fixes."
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
