//
//  ColorPalette.swift
//  FoundationLab
//

import Foundation
import FoundationModels
import UniformTypeIdentifiers

nonisolated struct ColorPalette: Equatable, Sendable {
    let swatch: ColorSwatch
}

@available(iOS 27.2, macOS 27.2, visionOS 27.2, *)
nonisolated extension ColorPalette: DataEntryRepresentable {
    init(_ entry: Transcript.DataEntry) throws {
        swatch = try ColorSwatch(
            name: entry.metadata.value(String.self, forProperty: "source"),
            contentType: entry.contentType,
            expectedType: .foundationLabColorPalette,
            rgbData: entry.content
        )
    }

    var transcriptRepresentation: Transcript.DataEntry {
        Transcript.DataEntry(
            contentType: .foundationLabColorPalette,
            content: swatch.rgbData,
            metadata: GeneratedContent(properties: ["source": swatch.name])
        )
    }
}
