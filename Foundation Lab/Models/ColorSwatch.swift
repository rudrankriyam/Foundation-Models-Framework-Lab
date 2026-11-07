//
//  ColorSwatch.swift
//  FoundationLab
//

import Foundation
import FoundationModels
import UniformTypeIdentifiers

nonisolated extension UTType {
    static let foundationLabColorSwatch = UTType(
        exportedAs: "com.rudrankriyam.foundationlab.color-swatch",
        conformingTo: .data
    )
    static let foundationLabColorPalette = UTType(
        exportedAs: "com.rudrankriyam.foundationlab.color-palette",
        conformingTo: .data
    )
}

nonisolated enum ColorSwatchDecodingError: LocalizedError {
    case unexpectedContentType(String)
    case malformedContent(Int)

    var errorDescription: String? {
        switch self {
        case .unexpectedContentType(let identifier):
            return String(localized: "Unexpected content type \(identifier).")
        case .malformedContent(let byteCount):
            return String(localized: "\(byteCount) bytes is not a whole number of RGB colors.")
        }
    }
}

nonisolated struct ColorSwatch: Equatable, Sendable {
    let name: String
    let colors: [UInt32]

    var rgbData: Data {
        Data(colors.flatMap { [UInt8($0 >> 16 & 0xFF), UInt8($0 >> 8 & 0xFF), UInt8($0 & 0xFF)] })
    }

    var hexValues: String {
        colors.map { String(format: "#%06X", $0) }.joined(separator: " ")
    }

    init(name: String, colors: [UInt32]) {
        self.name = name
        self.colors = colors
    }

    init(name: String, contentType: UTType, expectedType: UTType, rgbData: Data) throws {
        guard contentType == expectedType else {
            throw ColorSwatchDecodingError.unexpectedContentType(contentType.identifier)
        }
        guard rgbData.count.isMultiple(of: 3) else {
            throw ColorSwatchDecodingError.malformedContent(rgbData.count)
        }
        let bytes = [UInt8](rgbData)
        self.name = name
        colors = stride(from: 0, to: bytes.count, by: 3).map {
            UInt32(bytes[$0]) << 16 | UInt32(bytes[$0 + 1]) << 8 | UInt32(bytes[$0 + 2])
        }
    }

    var complement: ColorSwatch {
        ColorSwatch(name: name, colors: colors.map { 0xFFFFFF - $0 })
    }
}

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
nonisolated extension ColorSwatch: DataAttachmentRepresentable {
    init(_ attachment: Transcript.DataAttachment) throws {
        try self.init(
            name: attachment.metadata.value(String.self, forProperty: "name"),
            contentType: attachment.contentType,
            expectedType: .foundationLabColorSwatch,
            rgbData: attachment.content
        )
    }

    var transcriptRepresentation: Transcript.DataAttachment {
        Transcript.DataAttachment(
            contentType: .foundationLabColorSwatch,
            content: rgbData,
            metadata: GeneratedContent(properties: ["name": name])
        )
    }
}
