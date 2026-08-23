//
//  DynamicProfileWorkflowStage.swift
//  FoundationLab
//

#if compiler(>=6.4)
import Foundation

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
nonisolated enum DynamicProfileWorkflowStage: String, CaseIterable, Identifiable, Sendable {
    case inspect
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .inspect: String(localized: "Inspect")
        case .review: String(localized: "Review")
        }
    }

    var summary: String {
        switch self {
        case .inspect:
            String(localized: "Require a read-only local tool call and ground the answer in its sample output.")
        case .review:
            String(localized: "Remove the tool, keep the session history, and assess only the evidence already recorded.")
        }
    }

    var systemImage: String {
        switch self {
        case .inspect: "doc.text.magnifyingglass"
        case .review: "checkmark.seal"
        }
    }

    var defaultPrompt: String {
        switch self {
        case .inspect:
            String(localized: "Inspect the foundation-lab sample release record. Report its stored validation results and status.")
        case .review:
            String(localized: "Review the recorded evidence. Is this sample release ready, and which checks are still unknown?")
        }
    }
}
#endif
