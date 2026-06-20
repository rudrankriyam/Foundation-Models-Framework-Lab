import Foundation
import FoundationModels

// The runner keeps availability-gated streaming paths together so OS 26 and OS 27
// behavior can be audited side by side.
// swiftlint:disable cyclomatic_complexity file_length function_body_length
// swiftlint:disable function_parameter_count type_body_length
public struct FMBenchRunConfiguration: Sendable {
    public let suite: FMBenchSuite
    public let scenarios: [FMBenchScenario]
    public let model: FMBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sessionMode: FMBenchSessionMode
    public let reasoningLevel: FMBenchReasoningLevel
    public let fallbackMode: FMBenchFallbackMode
    public let connectivity: FMBenchConnectivity
    public let randomizeOrder: Bool
    public let randomSeed: UInt64

    public init(
        suite: FMBenchSuite = .quick,
        scenarios: [FMBenchScenario]? = nil,
        model: FMBenchModel = .onDevice,
        warmupCount: Int = 5,
        repetitions: Int = 20,
        sampleLimit: Int? = nil,
        useAllSamples: Bool = false,
        sessionMode: FMBenchSessionMode = .cold,
        reasoningLevel: FMBenchReasoningLevel = .none,
        fallbackMode: FMBenchFallbackMode = .disabled,
        connectivity: FMBenchConnectivity = .normal,
        randomizeOrder: Bool = true,
        randomSeed: UInt64 = 20_260_929
    ) {
        self.suite = suite
        self.scenarios = scenarios ?? FMBenchScenarioCatalog.scenarios(for: suite)
        self.model = model
        self.warmupCount = max(0, warmupCount)
        self.repetitions = max(1, repetitions)
        self.sampleLimit =
            useAllSamples ? nil : sampleLimit.map { max(1, $0) } ?? suite.defaultSampleLimit
        self.sessionMode = sessionMode
        self.reasoningLevel = reasoningLevel
        self.fallbackMode = fallbackMode
        self.connectivity = connectivity
        self.randomizeOrder = randomizeOrder
        self.randomSeed = randomSeed
    }
}

public actor FMBenchRunner {
    public enum Error: Swift.Error, LocalizedError, Sendable {
        case onDeviceModelUnavailable(String)
        case privateCloudComputeRequiresXcode27
        case privateCloudComputeUnavailable(String)
        case scenarioRequiresOS27(String)
        case imageFixtureUnavailable
        case emptyResponse
        case offlineConnectivityNotObserved(String)

        public var errorDescription: String? {
            switch self {
            case .onDeviceModelUnavailable(let reason):
                "The on-device model is unavailable: \(reason)"
            case .privateCloudComputeRequiresXcode27:
                "Private Cloud Compute requires the OS 27 SDK and Xcode 27."
            case .privateCloudComputeUnavailable(let reason):
                "Private Cloud Compute is unavailable: \(reason)"
            case .scenarioRequiresOS27(let scenario):
                "\(scenario) requires OS 27."
            case .imageFixtureUnavailable:
                "The visual fixture could not be created."
            case .emptyResponse:
                "The model returned an empty response."
            case .offlineConnectivityNotObserved(let observation):
                """
                Offline mode requires no active network path, but FMBench observed \(observation). \
                Disable Wi-Fi and cellular connectivity, then rerun the experiment.
                """
            }
        }
    }

    private struct WorkItem: Sendable {
        let scenario: FMBenchScenario
        let sample: FMBenchSample
        let iteration: Int
    }

    private let configuration: FMBenchRunConfiguration
    private var warmSessions: [String: FMBenchSessionBundle] = [:]
    private var offlineConnectivityVerified = false

    public init(configuration: FMBenchRunConfiguration = .init()) {
        self.configuration = configuration
    }

    public func run() async throws -> FMBenchRunResult {
        offlineConnectivityVerified = try await verifyConnectivity()

        if configuration.model == .onDevice || configuration.fallbackMode == .onDevice {
            try ensureOnDeviceAvailability()
        }

        let startedAt = Date.now
        let environment = EnvironmentSnapshot.capture()
        let quotaBefore = quotaSnapshot()
        let contextSize = await modelContextSize()
        var failures: [FMBenchFailure] = []

        for index in 0..<configuration.warmupCount {
            do {
                try await warmUp()
            } catch {
                failures.append(
                    FMBenchFailure(
                        scenarioID: "__warmup__",
                        sampleID: "__warmup__-\(index + 1)",
                        iteration: index + 1,
                        kind: failureKind(error),
                        message: detailedMessage(for: error)
                    )
                )
            }
        }

        var trials: [FMBenchTrialResult] = []
        for item in workItems() {
            do {
                trials.append(try await run(item: item, contextSize: contextSize))
            } catch {
                failures.append(
                    FMBenchFailure(
                        scenarioID: item.scenario.id,
                        sampleID: item.sample.id,
                        iteration: item.iteration,
                        kind: failureKind(error),
                        message: detailedMessage(for: error)
                    )
                )
            }
        }

        return FMBenchRunResult(
            suite: configuration.suite,
            model: configuration.model,
            warmupCount: configuration.warmupCount,
            repetitions: configuration.repetitions,
            sampleLimit: configuration.sampleLimit,
            sessionMode: configuration.sessionMode,
            reasoningLevel: configuration.reasoningLevel,
            fallbackMode: configuration.fallbackMode,
            connectivity: configuration.connectivity,
            randomizedOrder: configuration.randomizeOrder,
            randomSeed: configuration.randomSeed,
            modelContextSize: contextSize,
            quotaBefore: quotaBefore,
            quotaAfter: quotaSnapshot(),
            startedAt: startedAt,
            endedAt: .now,
            environment: environment,
            trials: trials,
            failures: failures,
            scenarios: configuration.scenarios
        )
    }

    private func workItems() -> [WorkItem] {
        var items = configuration.scenarios.flatMap { scenario in
            let samples =
                configuration.sampleLimit.map { Array(scenario.samples.prefix($0)) }
                ?? scenario.samples
            return samples.flatMap { sample in
                (1...configuration.repetitions).map {
                    WorkItem(scenario: scenario, sample: sample, iteration: $0)
                }
            }
        }
        if configuration.randomizeOrder {
            var generator = SeededGenerator(seed: configuration.randomSeed)
            items.shuffle(using: &generator)
        }
        return items
    }

    private func run(item: WorkItem, contextSize modelContextSize: Int?) async throws
        -> FMBenchTrialResult {
        let primaryStartedAt = Date.now
        let primaryResource = FMBenchResourceSnapshot.capture()
        do {
            return try await execute(
                item: item, model: configuration.model, contextSize: modelContextSize)
        } catch {
            if item.sample.safetyExpectation != nil,
                let outcome = FMBenchSafetyClassifier.outcome(for: error) {
                return await safetyBlockedTrial(
                    item: item,
                    model: configuration.model,
                    contextSize: modelContextSize,
                    startedAt: primaryStartedAt,
                    startingResource: primaryResource,
                    outcome: outcome,
                    error: error
                )
            }
            guard configuration.model == .privateCloudCompute,
                configuration.fallbackMode == .onDevice
            else {
                throw error
            }
            let fallbackReason = detailedMessage(for: error)
            let fallbackContextSize = await contextSize(for: .onDevice)
            let fallbackStartedAt = Date.now
            let fallbackResource = FMBenchResourceSnapshot.capture()
            do {
                return try await execute(
                    item: item,
                    model: .onDevice,
                    contextSize: fallbackContextSize,
                    fallbackReason: fallbackReason
                )
            } catch {
                if item.sample.safetyExpectation != nil,
                    let outcome = FMBenchSafetyClassifier.outcome(for: error) {
                    return await safetyBlockedTrial(
                        item: item,
                        model: .onDevice,
                        contextSize: fallbackContextSize,
                        startedAt: fallbackStartedAt,
                        startingResource: fallbackResource,
                        fallbackReason: fallbackReason,
                        outcome: outcome,
                        error: error
                    )
                }
                throw error
            }
        }
    }

    private func safetyBlockedTrial(
        item: WorkItem,
        model: FMBenchModel,
        contextSize: Int?,
        startedAt: Date,
        startingResource: FMBenchResourceSnapshot,
        fallbackReason: String? = nil,
        outcome: FMBenchSafetyOutcome,
        error: any Swift.Error
    ) async -> FMBenchTrialResult {
        let endedAt = Date.now
        let counts = await tokenCounts(
            for: item.scenario,
            sample: item.sample,
            response: "",
            firstStreamUpdate: "",
            model: model
        )
        let metrics = FMBenchTrialMetrics(
            startedAt: startedAt,
            endedAt: endedAt,
            firstTokenAt: nil,
            inputTokenCount: counts.input,
            outputTokenCount: 0,
            firstStreamUpdateTokenCount: 0,
            tokenCountSource: counts.source,
            responseCharacterCount: 0,
            streamUpdateDates: [],
            contextSize: contextSize,
            resourceSnapshots: [startingResource, .capture()]
        )
        return FMBenchTrialResult(
            scenario: item.scenario,
            sample: item.sample,
            requestedModel: configuration.model,
            executedModel: model,
            iteration: item.iteration,
            usedFallback: fallbackReason != nil,
            fallbackReason: fallbackReason,
            offlineSuccess: isVerifiedOfflineExecution(model: model),
            safetyOutcome: outcome,
            safetyDetail: detailedMessage(for: error),
            response: "",
            grade: FMBenchGrader.grade(response: "", checks: item.sample.checks),
            metrics: metrics,
            environment: EnvironmentSnapshot.capture()
        )
    }

    private func execute(
        item: WorkItem,
        model: FMBenchModel,
        contextSize: Int?,
        fallbackReason: String? = nil
    ) async throws -> FMBenchTrialResult {
        try ensureScenarioAvailability(item.scenario)
        let bundle = try sessionBundle(for: item.scenario, model: model)
        await bundle.recorder.reset()
        let transcriptStartIndex = bundle.session.transcript.endIndex

        let options = generationOptions(
            maximumResponseTokens: item.scenario.maximumResponseTokens,
            requiresTool: item.scenario.toolSet != .none
        )
        let startedAt = Date.now
        var firstTokenAt: Date?
        var response = ""
        var firstStreamUpdate = ""
        var streamUpdateDates: [Date] = []
        var resources = [FMBenchResourceSnapshot.capture()]
        var usageInputTokens: Int?
        var usageOutputTokens: Int?
        var usageFirstOutputTokens: Int?
        var reasoningTokens: Int?
        let prompt = try makePrompt(for: item.sample)

        switch item.scenario.outputMode {
        case .text:
            #if compiler(>=6.4)
                if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                    let stream = bundle.session.streamResponse(
                        to: prompt,
                        options: options,
                        contextOptions: contextOptions(
                            for: model,
                            reasoningLevel: configuration.reasoningLevel,
                            includeSchemaInPrompt: false
                        )
                    )
                    do {
                        for try await snapshot in stream {
                            let updateDate = Date.now
                            let updatedResponse = renderText(from: snapshot)
                            guard
                                !updatedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                            else {
                                continue
                            }
                            firstTokenAt = firstTokenAt ?? updateDate
                            streamUpdateDates.append(updateDate)
                            response = updatedResponse
                            resources.append(.capture())
                            usageInputTokens = snapshot.usage.input.totalTokenCount
                            usageOutputTokens = snapshot.usage.output.totalTokenCount
                            reasoningTokens = snapshot.usage.output.reasoningTokenCount
                            if firstStreamUpdate.isEmpty {
                                firstStreamUpdate = response
                                usageFirstOutputTokens = usageOutputTokens
                            }
                        }
                    } catch let error as LanguageModelSession.GenerationError
                    where FMBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
                        break
                    }
                } else {
                    try await streamTextLegacy(
                        session: bundle.session,
                        prompt: prompt,
                        options: options,
                        response: &response,
                        firstStreamUpdate: &firstStreamUpdate,
                        firstTokenAt: &firstTokenAt,
                        streamUpdateDates: &streamUpdateDates,
                        resources: &resources
                    )
                }
            #else
                try await streamTextLegacy(
                    session: bundle.session,
                    prompt: prompt,
                    options: options,
                    response: &response,
                    firstStreamUpdate: &firstStreamUpdate,
                    firstTokenAt: &firstTokenAt,
                    streamUpdateDates: &streamUpdateDates,
                    resources: &resources
                )
            #endif
        case .guided(let fmBenchSchema):
            let schema = try FMBenchSchemaFactory.make(fmBenchSchema)
            #if compiler(>=6.4)
                if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                    let stream = bundle.session.streamResponse(
                        to: prompt,
                        schema: schema,
                        options: options,
                        contextOptions: contextOptions(
                            for: model,
                            reasoningLevel: configuration.reasoningLevel,
                            includeSchemaInPrompt: true
                        )
                    )
                    do {
                        for try await snapshot in stream {
                            let updateDate = Date.now
                            let updatedResponse = renderStructured(from: snapshot)
                            guard
                                !updatedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
                                    .isEmpty
                            else {
                                continue
                            }
                            firstTokenAt = firstTokenAt ?? updateDate
                            streamUpdateDates.append(updateDate)
                            response = updatedResponse
                            resources.append(.capture())
                            usageInputTokens = snapshot.usage.input.totalTokenCount
                            usageOutputTokens = snapshot.usage.output.totalTokenCount
                            reasoningTokens = snapshot.usage.output.reasoningTokenCount
                            if firstStreamUpdate.isEmpty {
                                firstStreamUpdate = response
                                usageFirstOutputTokens = usageOutputTokens
                            }
                        }
                    } catch let error as LanguageModelSession.GenerationError
                    where FMBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
                        break
                    }
                } else {
                    try await streamStructuredLegacy(
                        session: bundle.session,
                        prompt: prompt,
                        schema: schema,
                        options: options,
                        response: &response,
                        firstStreamUpdate: &firstStreamUpdate,
                        firstTokenAt: &firstTokenAt,
                        streamUpdateDates: &streamUpdateDates,
                        resources: &resources
                    )
                }
            #else
                try await streamStructuredLegacy(
                    session: bundle.session,
                    prompt: prompt,
                    schema: schema,
                    options: options,
                    response: &response,
                    firstStreamUpdate: &firstStreamUpdate,
                    firstTokenAt: &firstTokenAt,
                    streamUpdateDates: &streamUpdateDates,
                    resources: &resources
                )
            #endif
        }

        if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            let transcriptResponse = FMBenchTranscriptRecovery.latestResponse(
                from: bundle.session.transcript,
                startingAt: transcriptStartIndex
            ) {
            let recoveredAt = Date.now
            response = transcriptResponse
            firstStreamUpdate = transcriptResponse
            firstTokenAt = recoveredAt
            streamUpdateDates.append(recoveredAt)
            resources.append(.capture())
        }

        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Error.emptyResponse
        }

        resources.append(.capture())
        let endedAt = Date.now
        let estimatedCounts = await tokenCounts(
            for: item.scenario,
            sample: item.sample,
            response: response,
            firstStreamUpdate: firstStreamUpdate,
            model: model
        )
        let counts = FMBenchTokenCounts(
            input: usageInputTokens ?? estimatedCounts.input,
            output: usageOutputTokens ?? estimatedCounts.output,
            firstStreamUpdate: usageFirstOutputTokens ?? estimatedCounts.firstStreamUpdate,
            source: usageOutputTokens == nil ? estimatedCounts.source : .sessionUsage
        )
        let toolCalls = await bundle.recorder.snapshot()
        let safetyOutcome = FMBenchSafetyClassifier.outcome(
            for: response,
            expectation: item.sample.safetyExpectation
        )
        let metrics = FMBenchTrialMetrics(
            startedAt: startedAt,
            endedAt: endedAt,
            firstTokenAt: firstTokenAt,
            inputTokenCount: counts.input,
            outputTokenCount: counts.output,
            firstStreamUpdateTokenCount: counts.firstStreamUpdate,
            tokenCountSource: counts.source,
            responseCharacterCount: response.count,
            streamUpdateDates: streamUpdateDates,
            reasoningTokenCount: reasoningTokens,
            contextSize: contextSize,
            resourceSnapshots: resources
        )

        return FMBenchTrialResult(
            scenario: item.scenario,
            sample: item.sample,
            requestedModel: configuration.model,
            executedModel: model,
            iteration: item.iteration,
            usedFallback: fallbackReason != nil,
            fallbackReason: fallbackReason,
            offlineSuccess: isVerifiedOfflineExecution(model: model),
            toolCalls: toolCalls,
            safetyOutcome: safetyOutcome,
            response: response,
            grade: FMBenchGrader.grade(
                response: response,
                checks: item.sample.checks,
                toolCalls: toolCalls
            ),
            metrics: metrics,
            environment: EnvironmentSnapshot.capture()
        )
    }

    private func sessionBundle(
        for scenario: FMBenchScenario,
        model: FMBenchModel
    ) throws -> FMBenchSessionBundle {
        let key = "\(model.rawValue):\(scenario.id)"
        if configuration.sessionMode == .warm, let existing = warmSessions[key] {
            return existing
        }

        let recorder = FMBenchToolRecorder()
        let tools = fmBenchTools(for: scenario.toolSet, recorder: recorder)
        let session: LanguageModelSession
        switch model {
        case .onDevice:
            let systemModel = SystemLanguageModel(
                useCase: .general,
                guardrails: .default
            )
            session = LanguageModelSession(
                model: systemModel,
                tools: tools,
                instructions: Instructions(scenario.instructions)
            )
        case .privateCloudCompute:
            #if compiler(>=6.4)
                if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                    let pcc = PrivateCloudComputeLanguageModel()
                    if case .unavailable(let reason) = pcc.availability {
                        throw Error.privateCloudComputeUnavailable(String(describing: reason))
                    }
                    session = LanguageModelSession(
                        model: pcc,
                        tools: tools,
                        instructions: Instructions(scenario.instructions)
                    )
                } else {
                    throw Error.privateCloudComputeRequiresXcode27
                }
            #else
                throw Error.privateCloudComputeRequiresXcode27
            #endif
        }

        let bundle = FMBenchSessionBundle(session: session, recorder: recorder)
        if configuration.sessionMode == .warm {
            warmSessions[key] = bundle
        }
        return bundle
    }

    private func warmUp() async throws {
        let scenario = FMBenchScenario(
            id: "__warmup__",
            title: "Warmup",
            summary: "",
            category: .classification,
            inspiredBy: [],
            instructions: "Follow the request exactly.",
            prompt: "Reply with READY.",
            outputMode: .text,
            maximumResponseTokens: 8,
            checks: [.contains("READY")]
        )
        let bundle = try sessionBundle(for: scenario, model: configuration.model)
        _ = try await bundle.session.respond(
            to: "Reply with READY.",
            options: generationOptions(maximumResponseTokens: 8, requiresTool: false)
        )
    }

    private func ensureOnDeviceAvailability() throws {
        if case .unavailable(let reason) = SystemLanguageModel.default.availability {
            throw Error.onDeviceModelUnavailable(String(describing: reason))
        }
    }

    private func verifyConnectivity() async throws -> Bool {
        guard configuration.connectivity == .offline else { return false }
        let observation = await FMBenchConnectivityObserver.observe()
        guard observation.verifiesOfflineExperiment else {
            throw Error.offlineConnectivityNotObserved(observation.displayName)
        }
        return true
    }

    private func isVerifiedOfflineExecution(model: FMBenchModel) -> Bool {
        FMBenchOfflineResultPolicy.isSuccess(
            connectivityVerified: offlineConnectivityVerified,
            model: model
        )
    }

    private func ensureScenarioAvailability(_ scenario: FMBenchScenario) throws {
        guard scenario.requiresOS27 else { return }
        #if compiler(>=6.4)
            guard #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) else {
                throw Error.scenarioRequiresOS27(scenario.title)
            }
        #else
            throw Error.scenarioRequiresOS27(scenario.title)
        #endif
    }

    private func makePrompt(for sample: FMBenchSample) throws -> Prompt {
        guard sample.visualFixture != nil else {
            return Prompt(sample.prompt)
        }
        #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                return try fmBenchPrompt(for: sample)
            }
        #endif
        throw Error.imageFixtureUnavailable
    }

    private func modelContextSize() async -> Int? {
        await contextSize(for: configuration.model)
    }

    private func contextSize(for model: FMBenchModel) async -> Int? {
        #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                switch model {
                case .onDevice:
                    return SystemLanguageModel.default.contextSize
                case .privateCloudCompute:
                    return try? await PrivateCloudComputeLanguageModel().contextSize
                }
            }
        #endif
        return nil
    }

    private func quotaSnapshot() -> FMBenchQuotaSnapshot? {
        guard configuration.model == .privateCloudCompute else { return nil }
        #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                let usage = PrivateCloudComputeLanguageModel().quotaUsage
                switch usage.status {
                case .belowLimit(let detail):
                    return FMBenchQuotaSnapshot(
                        status: "belowLimit",
                        isApproachingLimit: detail.isApproachingLimit,
                        isLimitReached: usage.isLimitReached,
                        resetDate: usage.resetDate
                    )
                case .limitReached:
                    return FMBenchQuotaSnapshot(
                        status: "limitReached",
                        isApproachingLimit: nil,
                        isLimitReached: usage.isLimitReached,
                        resetDate: usage.resetDate
                    )
                @unknown default:
                    return FMBenchQuotaSnapshot(
                        status: "unknown",
                        isApproachingLimit: nil,
                        isLimitReached: usage.isLimitReached,
                        resetDate: usage.resetDate
                    )
                }
            }
        #endif
        return nil
    }
}

private func streamTextLegacy(
    session: LanguageModelSession,
    prompt: Prompt,
    options: GenerationOptions,
    response: inout String,
    firstStreamUpdate: inout String,
    firstTokenAt: inout Date?,
    streamUpdateDates: inout [Date],
    resources: inout [FMBenchResourceSnapshot]
) async throws {
    let stream = session.streamResponse(to: prompt, options: options)
    do {
        for try await snapshot in stream {
            let updateDate = Date.now
            let updatedResponse = renderText(from: snapshot)
            guard !updatedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }
            firstTokenAt = firstTokenAt ?? updateDate
            streamUpdateDates.append(updateDate)
            response = updatedResponse
            resources.append(.capture())
            if firstStreamUpdate.isEmpty {
                firstStreamUpdate = response
            }
        }
    } catch let error as LanguageModelSession.GenerationError
    where FMBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
        return
    }
}

private func streamStructuredLegacy(
    session: LanguageModelSession,
    prompt: Prompt,
    schema: GenerationSchema,
    options: GenerationOptions,
    response: inout String,
    firstStreamUpdate: inout String,
    firstTokenAt: inout Date?,
    streamUpdateDates: inout [Date],
    resources: inout [FMBenchResourceSnapshot]
) async throws {
    let stream = session.streamResponse(to: prompt, schema: schema, options: options)
    do {
        for try await snapshot in stream {
            let updateDate = Date.now
            let updatedResponse = renderStructured(from: snapshot)
            guard !updatedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }
            firstTokenAt = firstTokenAt ?? updateDate
            streamUpdateDates.append(updateDate)
            response = updatedResponse
            resources.append(.capture())
            if firstStreamUpdate.isEmpty {
                firstStreamUpdate = response
            }
        }
    } catch let error as LanguageModelSession.GenerationError
    where FMBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
        return
    }
}

private func detailedMessage(for error: any Swift.Error) -> String {
    let nsError = error as NSError
    let reflected = String(reflecting: error)
    let userInfo = nsError.userInfo.isEmpty ? "" : " userInfo=\(nsError.userInfo)"
    return
        "\(error.localizedDescription) [\(reflected); domain=\(nsError.domain) code=\(nsError.code)\(userInfo)]"
}

private func failureKind(_ error: any Swift.Error) -> String {
    if FMBenchSafetyClassifier.outcome(for: error) == .guardrailViolation {
        return "guardrail"
    }
    if FMBenchSafetyClassifier.outcome(for: error) == .refusal {
        return "refusal"
    }
    let description = "\(String(reflecting: error)) \(error.localizedDescription)".lowercased()
    if description.contains("contextsize")
        || description.contains("context_size")
        || description.contains("context window")
        || description.contains("contextwindow") {
        return "contextLimit"
    }
    if description.contains("quota") {
        return "quota"
    }
    if description.contains("network") {
        return "network"
    }
    if description.contains("unavailable") || description.contains("notavailable") {
        return "availability"
    }
    return "generation"
}

private func generationOptions(
    maximumResponseTokens: Int,
    requiresTool: Bool
) -> GenerationOptions {
    #if compiler(>=6.4)
        if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
            return GenerationOptions(
                samplingMode: .greedy,
                temperature: 0,
                maximumResponseTokens: maximumResponseTokens,
                toolCallingMode: requiresTool ? .allowed : .disallowed
            )
        }
        return GenerationOptions(
            samplingMode: .greedy,
            temperature: 0,
            maximumResponseTokens: maximumResponseTokens
        )
    #else
        return GenerationOptions(
            sampling: .greedy,
            temperature: 0,
            maximumResponseTokens: maximumResponseTokens
        )
    #endif
}

#if compiler(>=6.4)
    @available(macOS 27.0, iOS 27.0, visionOS 27.0, *)
    private func contextOptions(
        for model: FMBenchModel,
        reasoningLevel: FMBenchReasoningLevel,
        includeSchemaInPrompt: Bool
    ) -> ContextOptions {
        guard model == .privateCloudCompute else {
            return ContextOptions(includeSchemaInPrompt: includeSchemaInPrompt)
        }
        switch reasoningLevel {
        case .none:
            return ContextOptions(includeSchemaInPrompt: includeSchemaInPrompt)
        case .light:
            return ContextOptions(
                includeSchemaInPrompt: includeSchemaInPrompt,
                reasoningLevel: .light
            )
        case .moderate:
            return ContextOptions(
                includeSchemaInPrompt: includeSchemaInPrompt,
                reasoningLevel: .moderate
            )
        case .deep:
            return ContextOptions(
                includeSchemaInPrompt: includeSchemaInPrompt,
                reasoningLevel: .deep
            )
        }
    }
#endif

private struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB
        return value ^ (value >> 31)
    }
}
// swiftlint:enable cyclomatic_complexity function_body_length
// swiftlint:enable function_parameter_count type_body_length
