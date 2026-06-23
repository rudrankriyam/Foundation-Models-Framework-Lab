//
//  ImageInputRecipe.swift
//  FoundationLab
//

import Foundation

enum ImageInputRecipe: String, CaseIterable, Identifiable {
    case altText
    case screenshotBug
    case uiAudit

    var id: String { rawValue }

    var title: String {
        switch self {
        case .altText:
            String(localized: "Alt Text")
        case .screenshotBug:
            String(localized: "Bug Report")
        case .uiAudit:
            String(localized: "UI Audit")
        }
    }

    var prompt: String {
        switch self {
        case .altText:
            String(localized: "Generate concise alt text for this image. Describe only what is visibly supported.")
        case .screenshotBug:
            String(localized: "Turn this screenshot into a concise bug report. Separate visible evidence from inference.")
        case .uiAudit:
            String(localized: "Audit this UI screenshot for accessibility and layout issues. Describe only visible evidence.")
        }
    }

    var code: String {
        """
        import FoundationModels

        let image = Attachment<ImageAttachmentContent>(cgImage)
            .label("selected-image")

        let session = LanguageModelSession()
        let response = try await session.respond {
            prompt
            image
        }

        print(response.content)
        print(response.usage.totalTokenCount)
        print(session.transcript)
        """
    }
}
