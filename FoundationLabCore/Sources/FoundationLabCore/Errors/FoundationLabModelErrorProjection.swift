import Foundation
import FoundationModels

/// A stable, machine-readable view of Foundation Models failures across framework generations.
public struct FoundationLabModelErrorProjection: Sendable, Hashable, Codable {
    public enum Category: String, Sendable, Hashable, Codable {
        case contextSizeExceeded = "context_size_exceeded"
        case assetsUnavailable = "assets_unavailable"
        case guardrailViolation = "guardrail_violation"
        case refusal
        case unsupportedCapability = "unsupported_capability"
        case unsupportedTranscriptContent = "unsupported_transcript_content"
        case unsupportedGenerationGuide = "unsupported_generation_guide"
        case unsupportedLanguageOrLocale = "unsupported_language_or_locale"
        case decodingFailure = "decoding_failure"
        case rateLimited = "rate_limited"
        case concurrentRequests = "concurrent_requests"
        case transcriptMutationWhileResponding = "transcript_mutation_while_responding"
        case timeout
        case networkFailure = "network_failure"
        case quotaLimitReached = "quota_limit_reached"
        case serviceUnavailable = "service_unavailable"
        case unknown
    }

    public enum Capability: String, Sendable, Hashable, Codable {
        case vision
        case guidedGeneration = "guided_generation"
        case reasoning
        case toolCalling = "tool_calling"
        case unknown
    }

    public let category: Category
    public let contextSize: Int?
    public let attemptedTokenCount: Int?
    public let resetDate: Date?
    public let capability: Capability?
    public let schemaName: String?
    public let languageCode: String?
    public let unsupportedTranscriptEntryCount: Int?
    public let hasQuotaLimitIncreaseSuggestion: Bool?

    public var isContextOverflow: Bool {
        category == .contextSizeExceeded
    }

    public static func isContextOverflow(_ error: any Error) -> Bool {
        project(error)?.isContextOverflow == true
    }

    public static func project(_ error: any Error) -> Self? {
        if let generationError = error as? LanguageModelSession.GenerationError {
            return project(generationError)
        }

        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            if let modelError = error as? FoundationModels.LanguageModelError {
                return project(modelError)
            }
            if let systemModelError = error as? SystemLanguageModel.Error {
                return project(systemModelError)
            }
            if let sessionError = error as? LanguageModelSession.Error {
                return project(sessionError)
            }
            if let privateCloudError = error as? PrivateCloudComputeLanguageModel.Error {
                return project(privateCloudError)
            }
            if let parsingError = error as? GeneratedContent.ParsingError {
                return project(parsingError)
            }
        }
        #endif

        return nil
    }

    private init(
        category: Category,
        contextSize: Int? = nil,
        attemptedTokenCount: Int? = nil,
        resetDate: Date? = nil,
        capability: Capability? = nil,
        schemaName: String? = nil,
        languageCode: String? = nil,
        unsupportedTranscriptEntryCount: Int? = nil,
        hasQuotaLimitIncreaseSuggestion: Bool? = nil
    ) {
        self.category = category
        self.contextSize = contextSize
        self.attemptedTokenCount = attemptedTokenCount
        self.resetDate = resetDate
        self.capability = capability
        self.schemaName = schemaName
        self.languageCode = languageCode
        self.unsupportedTranscriptEntryCount = unsupportedTranscriptEntryCount
        self.hasQuotaLimitIncreaseSuggestion = hasQuotaLimitIncreaseSuggestion
    }
}

private extension FoundationLabModelErrorProjection {
    static func project(_ error: LanguageModelSession.GenerationError) -> Self {
        switch error {
        case .exceededContextWindowSize:
            Self(category: .contextSizeExceeded)
        case .assetsUnavailable:
            Self(category: .assetsUnavailable)
        case .guardrailViolation:
            Self(category: .guardrailViolation)
        case .unsupportedGuide:
            Self(category: .unsupportedGenerationGuide)
        case .unsupportedLanguageOrLocale:
            Self(category: .unsupportedLanguageOrLocale)
        case .decodingFailure:
            Self(category: .decodingFailure)
        case .rateLimited:
            Self(category: .rateLimited)
        case .concurrentRequests:
            Self(category: .concurrentRequests)
        case .refusal:
            Self(category: .refusal)
        @unknown default:
            Self(category: .unknown)
        }
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_ error: FoundationModels.LanguageModelError) -> Self {
        switch error {
        case .contextSizeExceeded(let context):
            Self(
                category: .contextSizeExceeded,
                contextSize: context.contextSize,
                attemptedTokenCount: context.tokenCount
            )
        case .rateLimited(let context):
            Self(
                category: .rateLimited,
                resetDate: context.resetDate
            )
        case .guardrailViolation:
            Self(category: .guardrailViolation)
        case .refusal:
            Self(category: .refusal)
        case .unsupportedCapability(let context):
            Self(
                category: .unsupportedCapability,
                capability: project(context.capability)
            )
        case .unsupportedTranscriptContent(let context):
            Self(
                category: .unsupportedTranscriptContent,
                unsupportedTranscriptEntryCount: context.unsupportedContent.count
            )
        case .unsupportedGenerationGuide(let context):
            Self(
                category: .unsupportedGenerationGuide,
                schemaName: context.schemaName
            )
        case .unsupportedLanguageOrLocale(let context):
            Self(
                category: .unsupportedLanguageOrLocale,
                languageCode: context.languageCode.identifier
            )
        case .timeout:
            Self(category: .timeout)
        @unknown default:
            Self(category: .unknown)
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_ error: SystemLanguageModel.Error) -> Self {
        switch error {
        case .assetsUnavailable:
            Self(category: .assetsUnavailable)
        @unknown default:
            Self(category: .unknown)
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_ error: LanguageModelSession.Error) -> Self {
        switch error {
        case .concurrentRequests:
            Self(category: .concurrentRequests)
        case .transcriptMutationWhileResponding:
            Self(category: .transcriptMutationWhileResponding)
        @unknown default:
            Self(category: .unknown)
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_ error: PrivateCloudComputeLanguageModel.Error) -> Self {
        switch error {
        case .networkFailure:
            Self(category: .networkFailure)
        case .quotaLimitReached(let context):
            Self(
                category: .quotaLimitReached,
                resetDate: context.resetDate,
                hasQuotaLimitIncreaseSuggestion: context.limitIncreaseSuggestion != nil
            )
        case .serviceUnavailable:
            Self(category: .serviceUnavailable)
        @unknown default:
            Self(category: .unknown)
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_: GeneratedContent.ParsingError) -> Self {
        Self(category: .decodingFailure)
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    static func project(_ capability: LanguageModelCapabilities.Capability) -> Capability {
        if capability == .vision {
            return .vision
        }
        if capability == .guidedGeneration {
            return .guidedGeneration
        }
        if capability == .reasoning {
            return .reasoning
        }
        if capability == .toolCalling {
            return .toolCalling
        }
        return .unknown
    }
    #endif
}
