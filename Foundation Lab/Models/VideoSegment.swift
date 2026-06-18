//
//  VideoSegment.swift
//  FoundationLab
//
//  Created by Codex on 6/15/26.
//

import Foundation
import FoundationModels

#if compiler(>=6.4)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct VideoSegment: Transcript.CustomSegment {
    struct Content: Codable, Equatable, Sendable {
        let data: Data
        let mimeType: String
    }

    let id: String
    let content: Content

    init(
        id: String = UUID().uuidString,
        data: Data,
        mimeType: String
    ) {
        self.id = id
        content = Content(data: data, mimeType: mimeType)
    }
}
#endif
