//
//  ImageInputSelection.swift
//  FoundationLab
//

#if compiler(>=6.4)
import CoreGraphics
import Foundation
import ImageIO

struct ImageInputSelection: Identifiable {
    let id: UUID
    let fileName: String
    let data: Data
    let previewImage: CGImage
    let pixelWidth: Int
    let pixelHeight: Int
    let formatDescription: String
    let orientation: CGImagePropertyOrientation

    var byteCount: Int { data.count }

    var fileSizeDescription: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }

    var pixelDimensions: String {
        "\(pixelWidth) × \(pixelHeight)"
    }
}
#endif
