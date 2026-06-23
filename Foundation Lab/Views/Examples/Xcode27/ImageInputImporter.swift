//
//  ImageInputImporter.swift
//  FoundationLab
//

#if compiler(>=6.4)
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

actor ImageInputImporter {
    static let maximumEncodedByteCount: Int64 = 64 * 1_024 * 1_024
    static let maximumDecodedByteCount: Int64 = 256 * 1_024 * 1_024

    func load(_ url: URL) throws -> ImageInputSelection {
        let accessedSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        if let fileSize = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            try Self.validateEncodedByteCount(Int64(fileSize))
        }

        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            throw ImageInputImportError.unreadableFile
        }
        try Self.validateEncodedByteCount(Int64(data.count))
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageInputImportError.unsupportedImage
        }

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
        guard let width = (properties?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0,
              height > 0 else {
            throw ImageInputImportError.missingDimensions
        }
        try Self.validateDecodedDimensions(width: width, height: height)

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1_600
        ] as CFDictionary
        guard let previewImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw ImageInputImportError.unsupportedImage
        }

        let orientationValue = (properties?[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
        let orientation = CGImagePropertyOrientation(rawValue: orientationValue) ?? .up
        let typeIdentifier = CGImageSourceGetType(source) as String?
        let formatDescription = typeIdentifier
            .flatMap { UTType($0)?.localizedDescription }
            ?? String(localized: "Image")

        return ImageInputSelection(
            id: UUID(),
            fileName: url.lastPathComponent,
            data: data,
            previewImage: previewImage,
            pixelWidth: width,
            pixelHeight: height,
            formatDescription: formatDescription,
            orientation: orientation
        )
    }

    func fullResolutionImage(from data: Data) throws -> CGImage {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(
                source,
                0,
                [kCGImageSourceShouldCache: false] as CFDictionary
              ) else {
            throw ImageInputImportError.unsupportedImage
        }
        try Self.validateDecodedBuffer(bytesPerRow: image.bytesPerRow, height: image.height)
        return image
    }

    nonisolated static func validateEncodedByteCount(_ byteCount: Int64) throws {
        guard byteCount <= maximumEncodedByteCount else {
            throw ImageInputImportError.fileTooLarge(
                actualByteCount: byteCount,
                maximumByteCount: maximumEncodedByteCount
            )
        }
    }

    nonisolated static func validateDecodedDimensions(width: Int, height: Int) throws {
        let estimatedByteCount = estimatedDecodedByteCount(width: width, height: height)
        try validateDecodedByteCount(estimatedByteCount)
    }

    nonisolated static func validateDecodedBuffer(bytesPerRow: Int, height: Int) throws {
        try validateDecodedByteCount(decodedByteCount(bytesPerRow: bytesPerRow, height: height))
    }

    nonisolated static func estimatedDecodedByteCount(width: Int, height: Int) -> Int64 {
        guard width > 0, height > 0 else { return 0 }

        let (rowBytes, rowOverflow) = Int64(width).multipliedReportingOverflow(by: 4)
        guard !rowOverflow else { return .max }

        let (paddedRowBytes, paddingOverflow) = rowBytes.addingReportingOverflow(15)
        guard !paddingOverflow else { return .max }

        let alignedRowBytes = (paddedRowBytes / 16) * 16
        let (decodedByteCount, decodedOverflow) = alignedRowBytes.multipliedReportingOverflow(by: Int64(height))
        return decodedOverflow ? .max : decodedByteCount
    }

    nonisolated static func decodedByteCount(bytesPerRow: Int, height: Int) -> Int64 {
        guard let rowByteCount = Int64(exactly: bytesPerRow),
              let rowCount = Int64(exactly: height),
              rowByteCount >= 0,
              rowCount >= 0 else {
            return .max
        }

        let (decodedByteCount, overflow) = rowByteCount.multipliedReportingOverflow(by: rowCount)
        return overflow ? .max : decodedByteCount
    }

    private nonisolated static func validateDecodedByteCount(_ byteCount: Int64) throws {
        guard byteCount <= maximumDecodedByteCount else {
            throw ImageInputImportError.decodedImageTooLarge(
                byteCount: byteCount,
                maximumByteCount: maximumDecodedByteCount
            )
        }
    }
}
#endif
