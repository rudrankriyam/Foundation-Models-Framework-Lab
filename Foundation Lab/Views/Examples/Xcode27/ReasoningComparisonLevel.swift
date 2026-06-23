//
//  ReasoningComparisonLevel.swift
//  FoundationLab
//

import Foundation
#if compiler(>=6.4)
import FoundationModels
#endif

nonisolated enum ReasoningComparisonLevel: String, CaseIterable, Identifiable, Sendable {
    case light
    case moderate
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            String(localized: "Light")
        case .moderate:
            String(localized: "Moderate")
        case .deep:
            String(localized: "Deep")
        }
    }

    var requestedBudgetDescription: String {
        switch self {
        case .light:
            String(localized: "Requests a light reasoning budget for this response.")
        case .moderate:
            String(localized: "Requests a moderate reasoning budget for this response.")
        case .deep:
            String(localized: "Requests a deep reasoning budget for this response.")
        }
    }

    var code: String {
        """
        import FoundationModels

        let model = PrivateCloudComputeLanguageModel()
        let session = LanguageModelSession(model: model)
        let response = try await session.respond(
            to: prompt,
            contextOptions: ContextOptions(reasoningLevel: .\(rawValue))
        )

        print(response.content)
        print(response.usage.output.reasoningTokenCount)
        """
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    var frameworkValue: ContextOptions.ReasoningLevel {
        switch self {
        case .light:
            .light
        case .moderate:
            .moderate
        case .deep:
            .deep
        }
    }
    #endif
}
