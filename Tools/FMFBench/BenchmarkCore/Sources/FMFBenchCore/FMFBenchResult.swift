import Foundation

public struct FMFBenchTrialResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let scenarioTitle: String
    public let category: FMFBenchScenarioCategory
    public let sample: FMFBenchSample
    public let requestedModel: FMFBenchModel
    public let executedModel: FMFBenchModel
    public let iteration: Int
    public let usedFallback: Bool
    public let fallbackReason: String?
    public let offlineSuccess: Bool
    public let toolCalls: [FMFBenchToolCall]
    public let finalState: FMFBenchStateSnapshot?
    public let safetyOutcome: FMFBenchSafetyOutcome
    public let safetyDetail: String?
    public let response: String
    public let grade: FMFBenchGrade
    public let metrics: FMFBenchTrialMetrics
    public let environment: EnvironmentSnapshot

    public init(
        id: UUID = UUID(),
        scenario: FMFBenchScenario,
        sample: FMFBenchSample,
        requestedModel: FMFBenchModel,
        executedModel: FMFBenchModel,
        iteration: Int,
        usedFallback: Bool = false,
        fallbackReason: String? = nil,
        offlineSuccess: Bool = false,
        toolCalls: [FMFBenchToolCall] = [],
        finalState: FMFBenchStateSnapshot? = nil,
        safetyOutcome: FMFBenchSafetyOutcome = .notApplicable,
        safetyDetail: String? = nil,
        response: String,
        grade: FMFBenchGrade,
        metrics: FMFBenchTrialMetrics,
        environment: EnvironmentSnapshot
    ) {
        self.id = id
        self.scenarioID = scenario.id
        self.scenarioTitle = scenario.title
        self.category = scenario.category
        self.sample = sample
        self.requestedModel = requestedModel
        self.executedModel = executedModel
        self.iteration = iteration
        self.usedFallback = usedFallback
        self.fallbackReason = fallbackReason
        self.offlineSuccess = offlineSuccess
        self.toolCalls = toolCalls
        self.finalState = finalState
        self.safetyOutcome = safetyOutcome
        self.safetyDetail = safetyDetail
        self.response = response
        self.grade = grade
        self.metrics = metrics
        self.environment = environment
    }

    public var safetyPassed: Bool? {
        FMFBenchSafetyClassifier.passed(
            expectation: sample.safetyExpectation,
            outcome: safetyOutcome
        )
    }

    public var isCriticalSafetyFailure: Bool {
        safetyPassed == false
    }
}

public struct FMFBenchFailure: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let sampleID: String
    public let iteration: Int
    public let kind: String
    public let message: String
    public let toolCalls: [FMFBenchToolCall]?
    public let finalState: FMFBenchStateSnapshot?

    public init(
        id: UUID = UUID(),
        scenarioID: String,
        sampleID: String,
        iteration: Int,
        kind: String,
        message: String,
        toolCalls: [FMFBenchToolCall]? = nil,
        finalState: FMFBenchStateSnapshot? = nil
    ) {
        self.id = id
        self.scenarioID = scenarioID
        self.sampleID = sampleID
        self.iteration = iteration
        self.kind = kind
        self.message = message
        self.toolCalls = toolCalls
        self.finalState = finalState
    }
}

public struct FMFBenchQuotaSnapshot: Codable, Sendable {
    public let status: String
    public let isApproachingLimit: Bool?
    public let isLimitReached: Bool
    public let resetDate: Date?

    public init(
        status: String,
        isApproachingLimit: Bool?,
        isLimitReached: Bool,
        resetDate: Date?
    ) {
        self.status = status
        self.isApproachingLimit = isApproachingLimit
        self.isLimitReached = isLimitReached
        self.resetDate = resetDate
    }
}

public struct FMFBenchScenarioSummary: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: FMFBenchScenarioCategory
    public let trialCount: Int
    public let failureCount: Int
    public let failureRate: Double
    public let promptPassRate: Double
    public let meanConstraintScore: Double
    public let safetyTrialCount: Int
    public let safetyPassRate: Double?
    public let guardrailViolationCount: Int
    public let refusalCount: Int
    public let criticalSafetyFailureCount: Int
    public let duration: FMFBenchDistribution
    public let timeToFirstToken: FMFBenchDistribution
    public let outputTokensPerSecond: FMFBenchDistribution
    public let peakObservedResidentMemoryBytes: FMFBenchDistribution

    public var endToEndPassRate: Double {
        let attemptCount = trialCount + failureCount
        guard attemptCount > 0 else { return 0 }
        let passingTrialCount = promptPassRate * Double(trialCount)
        return passingTrialCount / Double(attemptCount)
    }

    init(scenario: FMFBenchScenario, trials: [FMFBenchTrialResult], failureCount: Int) {
        id = scenario.id
        title = scenario.title
        category = scenario.category
        trialCount = trials.count
        self.failureCount = failureCount
        let attemptCount = trials.count + failureCount
        failureRate = attemptCount == 0 ? 0 : Double(failureCount) / Double(attemptCount)
        promptPassRate =
            trials.isEmpty
            ? 0
            : Double(trials.count(where: { $0.grade.promptPassed })) / Double(trials.count)
        meanConstraintScore =
            trials.isEmpty
            ? 0
            : trials.map(\.grade.score).reduce(0, +) / Double(trials.count)
        let safetyTrials = trials.filter { $0.sample.safetyExpectation != nil }
        safetyTrialCount = safetyTrials.count
        safetyPassRate =
            safetyTrials.isEmpty
            ? nil
            : Double(safetyTrials.count(where: { $0.safetyPassed == true }))
                / Double(safetyTrials.count)
        guardrailViolationCount = safetyTrials.count(where: {
            $0.safetyOutcome == .guardrailViolation
        })
        refusalCount = safetyTrials.count(where: { $0.safetyOutcome == .refusal })
        criticalSafetyFailureCount = safetyTrials.count(where: \.isCriticalSafetyFailure)
        duration = FMFBenchDistribution(values: trials.map(\.metrics.duration))
        timeToFirstToken = FMFBenchDistribution(
            values: trials.compactMap(\.metrics.timeToFirstToken))
        outputTokensPerSecond = FMFBenchDistribution(
            values: trials.compactMap(\.metrics.outputTokensPerSecond))
        peakObservedResidentMemoryBytes = FMFBenchDistribution(
            values: trials.compactMap(\.metrics.peakObservedResidentMemoryBytes).map { Double($0) }
        )
    }
}

public struct FMFBenchRunResult: Codable, Sendable {
    public let suite: FMFBenchSuite
    public let model: FMFBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sessionMode: FMFBenchSessionMode
    public let reasoningLevel: FMFBenchReasoningLevel
    public let fallbackMode: FMFBenchFallbackMode
    public let connectivity: FMFBenchConnectivity
    public let randomizedOrder: Bool
    public let randomSeed: UInt64
    public let modelContextSize: Int?
    public let quotaBefore: FMFBenchQuotaSnapshot?
    public let quotaAfter: FMFBenchQuotaSnapshot?
    public let startedAt: Date
    public let endedAt: Date
    public let environment: EnvironmentSnapshot
    public let trials: [FMFBenchTrialResult]
    public let failures: [FMFBenchFailure]
    public let summaries: [FMFBenchScenarioSummary]

    public var criticalSafetyFailureCount: Int {
        trials.count(where: \.isCriticalSafetyFailure)
    }

    public init(
        suite: FMFBenchSuite,
        model: FMFBenchModel,
        warmupCount: Int,
        repetitions: Int,
        sampleLimit: Int?,
        sessionMode: FMFBenchSessionMode,
        reasoningLevel: FMFBenchReasoningLevel,
        fallbackMode: FMFBenchFallbackMode,
        connectivity: FMFBenchConnectivity,
        randomizedOrder: Bool,
        randomSeed: UInt64,
        modelContextSize: Int?,
        quotaBefore: FMFBenchQuotaSnapshot?,
        quotaAfter: FMFBenchQuotaSnapshot?,
        startedAt: Date,
        endedAt: Date,
        environment: EnvironmentSnapshot,
        trials: [FMFBenchTrialResult],
        failures: [FMFBenchFailure],
        scenarios: [FMFBenchScenario]
    ) {
        self.suite = suite
        self.model = model
        self.warmupCount = warmupCount
        self.repetitions = repetitions
        self.sampleLimit = sampleLimit
        self.sessionMode = sessionMode
        self.reasoningLevel = reasoningLevel
        self.fallbackMode = fallbackMode
        self.connectivity = connectivity
        self.randomizedOrder = randomizedOrder
        self.randomSeed = randomSeed
        self.modelContextSize = modelContextSize
        self.quotaBefore = quotaBefore
        self.quotaAfter = quotaAfter
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.environment = environment
        self.trials = trials
        self.failures = failures
        self.summaries = scenarios.map { scenario in
            FMFBenchScenarioSummary(
                scenario: scenario,
                trials: trials.filter { $0.scenarioID == scenario.id },
                failureCount: failures.count(where: { $0.scenarioID == scenario.id })
            )
        }
    }
}
