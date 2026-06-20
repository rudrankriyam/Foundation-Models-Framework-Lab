import Foundation

public struct FMBenchTrialResult: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let scenarioTitle: String
    public let category: FMBenchScenarioCategory
    public let sample: FMBenchSample
    public let requestedModel: FMBenchModel
    public let executedModel: FMBenchModel
    public let iteration: Int
    public let usedFallback: Bool
    public let fallbackReason: String?
    public let offlineSuccess: Bool
    public let toolCalls: [FMBenchToolCall]
    public let finalState: FMBenchStateSnapshot?
    public let safetyOutcome: FMBenchSafetyOutcome
    public let safetyDetail: String?
    public let response: String
    public let grade: FMBenchGrade
    public let metrics: FMBenchTrialMetrics
    public let environment: EnvironmentSnapshot

    public init(
        id: UUID = UUID(),
        scenario: FMBenchScenario,
        sample: FMBenchSample,
        requestedModel: FMBenchModel,
        executedModel: FMBenchModel,
        iteration: Int,
        usedFallback: Bool = false,
        fallbackReason: String? = nil,
        offlineSuccess: Bool = false,
        toolCalls: [FMBenchToolCall] = [],
        finalState: FMBenchStateSnapshot? = nil,
        safetyOutcome: FMBenchSafetyOutcome = .notApplicable,
        safetyDetail: String? = nil,
        response: String,
        grade: FMBenchGrade,
        metrics: FMBenchTrialMetrics,
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
        FMBenchSafetyClassifier.passed(
            expectation: sample.safetyExpectation,
            outcome: safetyOutcome
        )
    }

    public var isCriticalSafetyFailure: Bool {
        safetyPassed == false
    }
}

public struct FMBenchFailure: Codable, Identifiable, Sendable {
    public let id: UUID
    public let scenarioID: String
    public let sampleID: String
    public let iteration: Int
    public let kind: String
    public let message: String
    public let toolCalls: [FMBenchToolCall]?
    public let finalState: FMBenchStateSnapshot?

    public init(
        id: UUID = UUID(),
        scenarioID: String,
        sampleID: String,
        iteration: Int,
        kind: String,
        message: String,
        toolCalls: [FMBenchToolCall]? = nil,
        finalState: FMBenchStateSnapshot? = nil
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

public struct FMBenchQuotaSnapshot: Codable, Sendable {
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

public struct FMBenchScenarioSummary: Codable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let category: FMBenchScenarioCategory
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
    public let duration: FMBenchDistribution
    public let timeToFirstToken: FMBenchDistribution
    public let outputTokensPerSecond: FMBenchDistribution
    public let peakObservedResidentMemoryBytes: FMBenchDistribution

    public var endToEndPassRate: Double {
        let attemptCount = trialCount + failureCount
        guard attemptCount > 0 else { return 0 }
        let passingTrialCount = promptPassRate * Double(trialCount)
        return passingTrialCount / Double(attemptCount)
    }

    init(scenario: FMBenchScenario, trials: [FMBenchTrialResult], failureCount: Int) {
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
        duration = FMBenchDistribution(values: trials.map(\.metrics.duration))
        timeToFirstToken = FMBenchDistribution(
            values: trials.compactMap(\.metrics.timeToFirstToken))
        outputTokensPerSecond = FMBenchDistribution(
            values: trials.compactMap(\.metrics.outputTokensPerSecond))
        peakObservedResidentMemoryBytes = FMBenchDistribution(
            values: trials.compactMap(\.metrics.peakObservedResidentMemoryBytes).map { Double($0) }
        )
    }
}

public struct FMBenchRunResult: Codable, Sendable {
    public let suite: FMBenchSuite
    public let model: FMBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sessionMode: FMBenchSessionMode
    public let reasoningLevel: FMBenchReasoningLevel
    public let fallbackMode: FMBenchFallbackMode
    public let connectivity: FMBenchConnectivity
    public let randomizedOrder: Bool
    public let randomSeed: UInt64
    public let modelContextSize: Int?
    public let quotaBefore: FMBenchQuotaSnapshot?
    public let quotaAfter: FMBenchQuotaSnapshot?
    public let startedAt: Date
    public let endedAt: Date
    public let environment: EnvironmentSnapshot
    public let trials: [FMBenchTrialResult]
    public let failures: [FMBenchFailure]
    public let summaries: [FMBenchScenarioSummary]

    public var criticalSafetyFailureCount: Int {
        trials.count(where: \.isCriticalSafetyFailure)
    }

    public init(
        suite: FMBenchSuite,
        model: FMBenchModel,
        warmupCount: Int,
        repetitions: Int,
        sampleLimit: Int?,
        sessionMode: FMBenchSessionMode,
        reasoningLevel: FMBenchReasoningLevel,
        fallbackMode: FMBenchFallbackMode,
        connectivity: FMBenchConnectivity,
        randomizedOrder: Bool,
        randomSeed: UInt64,
        modelContextSize: Int?,
        quotaBefore: FMBenchQuotaSnapshot?,
        quotaAfter: FMBenchQuotaSnapshot?,
        startedAt: Date,
        endedAt: Date,
        environment: EnvironmentSnapshot,
        trials: [FMBenchTrialResult],
        failures: [FMBenchFailure],
        scenarios: [FMBenchScenario]
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
            FMBenchScenarioSummary(
                scenario: scenario,
                trials: trials.filter { $0.scenarioID == scenario.id },
                failureCount: failures.count(where: { $0.scenarioID == scenario.id })
            )
        }
    }
}
