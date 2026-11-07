//
//  DynamicProfileInstructionEvent.swift
//  FoundationLab
//

import Foundation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated struct DynamicProfileInstructionEvent: Identifiable, Sendable {
    nonisolated enum Kind: Sendable {
        case activated
        case deactivated

        var title: String {
            switch self {
            case .activated: String(localized: "Activated")
            case .deactivated: String(localized: "Deactivated")
            }
        }

        var systemImage: String {
            switch self {
            case .activated: "play.circle"
            case .deactivated: "stop.circle"
            }
        }
    }

    let id = UUID()
    let sequence: Int
    let kind: Kind
    let stage: DynamicProfileWorkflowStage
    let runtime: DynamicProfileReviewRuntime
}
