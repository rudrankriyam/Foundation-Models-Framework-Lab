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
    private static let readChunkByteCount = 1_024 * 1_024

    func load(_ url: URL) async throws -> ImageInputSelection {
        let accessedSecurityScope = url.startAccessingSecurityScopedResource()
        defer {
            if accessedSecurityScope {
                url.stopAccessingSecurityScopedResource()
            }
        }

        try Task.checkCancellation()
        let data = try await Self.coordinatedOwnedData(from: url)
        try Task.checkCancellation()

        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageInputImportError.unsupportedImage
        }
        try Task.checkCancellation()

        let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary?
        guard let width = (properties?[kCGImagePropertyPixelWidth] as? NSNumber)?.intValue,
              let height = (properties?[kCGImagePropertyPixelHeight] as? NSNumber)?.intValue,
              width > 0,
              height > 0 else {
            throw ImageInputImportError.missingDimensions
        }
        try Self.validateDecodedDimensions(width: width, height: height)
        try Task.checkCancellation()

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 1_600
        ] as CFDictionary
        guard let previewImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            throw ImageInputImportError.unsupportedImage
        }
        try Task.checkCancellation()

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
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            throw ImageInputImportError.unsupportedImage
        }
        try Task.checkCancellation()
        guard let image = CGImageSourceCreateImageAtIndex(
            source,
            0,
            [kCGImageSourceShouldCache: false] as CFDictionary
        ) else {
            throw ImageInputImportError.unsupportedImage
        }
        try Task.checkCancellation()
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

    private nonisolated static func coordinatedOwnedData(from url: URL) async throws -> Data {
        let operation = ImageInputFileCoordination(url: url)

        return try await withTaskCancellationHandler {
            try operation.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                operation.coordinator.coordinate(with: [operation.intent], queue: operation.queue) { coordinationError in
                    if let coordinationError {
                        do {
                            try operation.checkCancellation()
                        } catch {
                            continuation.resume(throwing: error)
                            return
                        }

                        if (coordinationError as? CocoaError)?.code == .userCancelled {
                            continuation.resume(throwing: CancellationError())
                        } else {
                            continuation.resume(throwing: coordinationError)
                        }
                        return
                    }

                    do {
                        try operation.checkCancellation()
                        let coordinatedURL = operation.intent.url
                        let fileSize: Int? = try? coordinatedURL
                            .resourceValues(forKeys: [.fileSizeKey])
                            .fileSize
                        if let fileSize {
                            try validateEncodedByteCount(Int64(fileSize))
                        }

                        let data = try readOwnedData(from: coordinatedURL, operation: operation)
                        try validateEncodedByteCount(Int64(data.count))
                        try operation.checkCancellation()
                        continuation.resume(returning: data)
                    } catch is CancellationError {
                        continuation.resume(throwing: CancellationError())
                    } catch let error as ImageInputImportError {
                        continuation.resume(throwing: error)
                    } catch {
                        continuation.resume(throwing: ImageInputImportError.unreadableFile)
                    }
                }
            }
        } onCancel: {
            operation.cancel()
        }
    }

    private nonisolated static func readOwnedData(
        from url: URL,
        operation: ImageInputFileCoordination
    ) throws -> Data {
        try operation.checkCancellation()
        let fileHandle = try FileHandle(forReadingFrom: url)
        defer { try? fileHandle.close() }

        let maximumReadByteCount = Int(maximumEncodedByteCount) + 1
        var data = Data()
        while data.count < maximumReadByteCount {
            try operation.checkCancellation()
            let remainingByteCount = maximumReadByteCount - data.count
            let chunkByteCount = min(readChunkByteCount, remainingByteCount)
            guard let chunk = try fileHandle.read(upToCount: chunkByteCount), !chunk.isEmpty else {
                break
            }
            data.append(chunk)
        }
        try operation.checkCancellation()
        return data
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
