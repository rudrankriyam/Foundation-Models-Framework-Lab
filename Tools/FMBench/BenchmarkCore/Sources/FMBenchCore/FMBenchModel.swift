import Foundation

public enum FMBenchModel: String, CaseIterable, Codable, Identifiable, Sendable {
    case onDevice
    case privateCloudCompute

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .onDevice:
            "On-device"
        case .privateCloudCompute:
            "Private Cloud Compute"
        }
    }
}

public enum FMBenchSuite: String, CaseIterable, Codable, Identifiable, Sendable {
    case quick
    case full
    case guardrails
    case performance
    case context

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .quick:
            "Practical Quick"
        case .full:
            "Practical Full"
        case .guardrails:
            "Safety Guardrails"
        case .performance:
            "Synthetic Performance"
        case .context:
            "Context Limits"
        }
    }

    public var defaultSampleLimit: Int? {
        switch self {
        case .quick:
            1
        case .full, .guardrails, .performance, .context:
            nil
        }
    }
}

public enum FMBenchScenarioCategory: String, Codable, CaseIterable, Sendable {
    case taskParsing
    case summarization
    case classification
    case workoutGeneration
    case groundedExplanation
    case exerciseSubstitution
    case documentQuestionAnswering
    case citationExtraction
    case creativeWriting
    case visualRecommendation
    case guardrailExpectedResponse
    case guardrailExpectedProtection
    case syntheticThroughput
    case contextLimits

    public var displayName: String {
        switch self {
        case .taskParsing:
            "Task parsing"
        case .summarization:
            "Summarization"
        case .classification:
            "Classification"
        case .workoutGeneration:
            "Workout generation"
        case .groundedExplanation:
            "Grounded explanation"
        case .exerciseSubstitution:
            "Exercise substitution"
        case .documentQuestionAnswering:
            "Document question answering"
        case .citationExtraction:
            "Citation extraction"
        case .creativeWriting:
            "Creative writing"
        case .visualRecommendation:
            "Visual recommendation"
        case .guardrailExpectedResponse:
            "Guardrail false positives"
        case .guardrailExpectedProtection:
            "Guardrail protection"
        case .syntheticThroughput:
            "Synthetic throughput"
        case .contextLimits:
            "Context limits"
        }
    }
}

public enum FMBenchOutputMode: Codable, Sendable {
    case text
    case guided(FMBenchSchema)
}

public enum FMBenchSchema: String, Codable, Sendable {
    case task
    case classification
    case workout
    case groundedAnswer
    case citation
}

public enum FMBenchSessionMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case cold
    case warm

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cold:
            "Cold session"
        case .warm:
            "Warm reused session"
        }
    }
}

public enum FMBenchReasoningLevel: String, CaseIterable, Codable, Identifiable, Sendable {
    case none
    case light
    case moderate
    case deep

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .none:
            "Default"
        case .light:
            "Light"
        case .moderate:
            "Moderate"
        case .deep:
            "Deep"
        }
    }
}

public enum FMBenchFallbackMode: String, CaseIterable, Codable, Identifiable, Sendable {
    case disabled
    case onDevice

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .disabled:
            "Disabled"
        case .onDevice:
            "Fall back on-device"
        }
    }
}

public enum FMBenchConnectivity: String, CaseIterable, Codable, Identifiable, Sendable {
    case normal
    case offline

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .normal:
            "Normal"
        case .offline:
            "Offline experiment"
        }
    }
}

public enum FMBenchToolSet: String, Codable, Sendable {
    case none
    case knowledge
    case exerciseCatalog
}

public enum FMBenchVisualFixture: String, Codable, Sendable {
    case sunsetRun
}

public enum FMBenchSafetyExpectation: String, Codable, Sendable {
    case mustRespond
    case mustProtect

    public var displayName: String {
        switch self {
        case .mustRespond:
            "Must respond"
        case .mustProtect:
            "Must protect"
        }
    }
}

public enum FMBenchSafetyOutcome: String, Codable, Sendable {
    case notApplicable
    case responded
    case guardrailViolation
    case refusal

    public var displayName: String {
        switch self {
        case .notApplicable:
            "Not applicable"
        case .responded:
            "Responded"
        case .guardrailViolation:
            "Guardrail violation"
        case .refusal:
            "Refusal"
        }
    }
}
