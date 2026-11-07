//
//  ImageInputRunResult.swift
//  FoundationLab
//

import Foundation

struct ImageInputRunResult: Identifiable {
    let id = UUID()
    let response: String
    let prompt: String
    let imageName: String
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningTokens: Int
    let totalTokens: Int
    let transcriptEntryCount: Int
    let attachmentSegmentCount: Int
    let duration: Duration
}
