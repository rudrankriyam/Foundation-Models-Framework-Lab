//
//  ImageInputImportError.swift
//  FoundationLab
//

import Foundation

enum ImageInputImportError: LocalizedError {
    case unreadableFile
    case unsupportedImage
    case missingDimensions
    case fileTooLarge(actualByteCount: Int64, maximumByteCount: Int64)
    case decodedImageTooLarge(estimatedByteCount: Int64, maximumByteCount: Int64)

    var errorDescription: String? {
        switch self {
        case .unreadableFile:
            String(localized: "Foundation Lab could not read that file.")
        case .unsupportedImage:
            String(localized: "That file could not be decoded as an image.")
        case .missingDimensions:
            String(localized: "The image does not report valid pixel dimensions.")
        case .fileTooLarge(let actualByteCount, let maximumByteCount):
            String(
                localized: """
                This file is \(Self.formattedByteCount(actualByteCount)), above the interactive lab's \
                \(Self.formattedByteCount(maximumByteCount)) import limit. Use Tools/ImageInputProbe for large-file stress tests.
                """
            )
        case .decodedImageTooLarge(let estimatedByteCount, let maximumByteCount):
            String(
                localized: """
                This image would decode to about \(Self.formattedByteCount(estimatedByteCount)), above the interactive lab's \
                \(Self.formattedByteCount(maximumByteCount)) safety limit. Use Tools/ImageInputProbe for resolution stress tests.
                """
            )
        }
    }

    private static func formattedByteCount(_ byteCount: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: byteCount, countStyle: .file)
    }
}
