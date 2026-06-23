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
        import Foundation
        import FoundationModels
        import ImageIO

        func analyzeImage(at imageURL: URL, prompt: String) async throws {
            guard let source = CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                throw CocoaError(.fileReadCorruptFile)
            }

            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
            let orientationValue = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
            let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up

            let image = Attachment<ImageAttachmentContent>(
                cgImage,
                orientation: orientation
            )
            .label("selected-image")

            let session = LanguageModelSession()
            let response = try await session.respond {
                prompt
                image
            }

            print(response.content)
            print(response.usage.totalTokenCount)
            print(session.transcript)
        }
        """
    }
}
