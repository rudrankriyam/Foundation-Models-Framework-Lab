import ArgumentParser
import Foundation
import FoundationModelsKit
import FoundationModels

enum AFMRuntimeError: LocalizedError, Sendable, Equatable {
    case invalidRequest(String)
    case unavailableCapability(String)
    case providerFailure(String)
    case fileWriteFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .unavailableCapability(let message):
            return "Unavailable capability: \(message)"
        case .providerFailure(let message):
            return "Provider failure: \(message)"
        case .fileWriteFailed(let message):
            return "File write failed: \(message)"
        }
    }
}

enum AFMFeedbackIssueCategory: String, Sendable, Hashable, Codable, CaseIterable {
    case unhelpful
    case tooVerbose = "too-verbose"
    case didNotFollowInstructions = "did-not-follow-instructions"
    case incorrect
    case stereotypeOrBias = "stereotype-or-bias"
    case suggestiveOrSexual = "suggestive-or-sexual"
    case vulgarOrOffensive = "vulgar-or-offensive"
    case triggeredGuardrailUnexpectedly = "triggered-guardrail-unexpectedly"
}

extension AFMFeedbackIssueCategory: ExpressibleByArgument {
    init?(argument: String) {
        let normalized = argument.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "unhelpful":
            self = .unhelpful
        case "too-verbose", "tooverbose":
            self = .tooVerbose
        case "did-not-follow-instructions", "didnotfollowinstructions":
            self = .didNotFollowInstructions
        case "incorrect":
            self = .incorrect
        case "stereotype-or-bias", "stereotypeorbias":
            self = .stereotypeOrBias
        case "suggestive-or-sexual", "suggestiveorsexual":
            self = .suggestiveOrSexual
        case "vulgar-or-offensive", "vulgaroroffensive":
            self = .vulgarOrOffensive
        case "triggered-guardrail-unexpectedly", "triggeredguardrailunexpectedly":
            self = .triggeredGuardrailUnexpectedly
        default:
            return nil
        }
    }

    var foundationModelsValue: LanguageModelFeedback.Issue.Category {
        switch self {
        case .unhelpful:
            return .unhelpful
        case .tooVerbose:
            return .tooVerbose
        case .didNotFollowInstructions:
            return .didNotFollowInstructions
        case .incorrect:
            return .incorrect
        case .stereotypeOrBias:
            return .stereotypeOrBias
        case .suggestiveOrSexual:
            return .suggestiveOrSexual
        case .vulgarOrOffensive:
            return .vulgarOrOffensive
        case .triggeredGuardrailUnexpectedly:
            return .triggeredGuardrailUnexpectedly
        }
    }
}

extension FoundationModelUseCase: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        let normalized = argument.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "general":
            self = .general
        case "content-tagging", "contenttagging", "tagging":
            self = .contentTagging
        default:
            return nil
        }
    }
}

extension FoundationModelGuardrails: @retroactive ExpressibleByArgument {
    public init?(argument: String) {
        let normalized = argument.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "default":
            self = .default
        case "permissive-content-transformations", "permissivecontenttransformations":
            self = .permissiveContentTransformations
        default:
            return nil
        }
    }

    var afmArgumentValue: String {
        switch self {
        case .default:
            return "default"
        case .permissiveContentTransformations:
            return "permissive-content-transformations"
        }
    }
}

struct AFMConversationExchange: Sendable, Hashable, Codable, Identifiable {
    let id: UUID
    let prompt: String
    let response: String
    let isError: Bool

    init(
        id: UUID = UUID(),
        prompt: String,
        response: String,
        isError: Bool
    ) {
        self.id = id
        self.prompt = prompt
        self.response = response
        self.isError = isError
    }
}
