//
//  SpotlightRAGDocument.swift
//  FoundationLab
//

import Foundation

struct SpotlightRAGDocument: Identifiable, Sendable {
    let id: String
    let title: String
    let body: String
    let keywords: [String]
    let modifiedAt: Date

    static let samples = [
        SpotlightRAGDocument(
            id: "kyoto-itinerary",
            title: "Kyoto itinerary",
            body: "Book dinner in Gion for Friday. Visit Fushimi Inari before 7 AM on Saturday to avoid the crowds.",
            keywords: ["Kyoto", "Gion", "Fushimi Inari", "travel"],
            modifiedAt: Date(timeIntervalSince1970: 1_772_323_200)
        ),
        SpotlightRAGDocument(
            id: "foundation-lab-release",
            title: "Foundation Lab release checklist",
            body: "Run SwiftLint, Swift package tests, and both macOS and iOS Simulator builds before opening the pull request.",
            keywords: ["Foundation Lab", "release", "testing"],
            modifiedAt: Date(timeIntervalSince1970: 1_781_740_800)
        ),
        SpotlightRAGDocument(
            id: "hike-notes",
            title: "Monsoon hike notes",
            body: "The lakeside route was quiet after the rain. Pack a shell and use the eastern trail when the lower path is muddy.",
            keywords: ["hike", "water", "rain", "trail"],
            modifiedAt: Date(timeIntervalSince1970: 1_775_088_000)
        ),
        SpotlightRAGDocument(
            id: "design-review",
            title: "Developer tool design review",
            body: "Keep the interface quiet and evidence-led. Show retrieved sources separately from the generated answer.",
            keywords: ["design", "developer tools", "retrieval", "sources"],
            modifiedAt: Date(timeIntervalSince1970: 1_779_235_200)
        )
    ]
}
