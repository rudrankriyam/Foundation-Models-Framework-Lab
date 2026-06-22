import Foundation
import FoundationModels

// The runner keeps availability-gated streaming paths together so OS 26 and OS 27
// behavior can be audited side by side.
// swiftlint:disable cyclomatic_complexity file_length function_body_length
// swiftlint:disable function_parameter_count type_body_length
public struct FMFBenchRunConfiguration: Sendable {
    public let suite: FMFBenchSuite
    public let scenarios: [FMFBenchScenario]
    public let model: FMFBenchModel
    public let warmupCount: Int
    public let repetitions: Int
    public let sampleLimit: Int?
    public let sampleIDs: Set<String>?
    public let sessionMode: FMFBenchSessionMode
    public let reasoningLevel: FMFBenchReasoningLevel
    public let fallbackMode: FMFBenchFallbackMode
    public let connectivity: FMFBenchConnectivity
    public let randomizeOrder: Bool
    public let randomSeed: UInt64

    public init(
        suite: FMFBenchSuite = .quick,
        scenarios: [FMFBenchScenario]? = nil,
        model: FMFBenchModel = .onDevice,
        warmupCount: Int = 5,
        repetitions: Int = 20,
        sampleLimit: Int? = nil,
        sampleIDs: Set<String>? = nil,
        useAllSamples: Bool = false,
        sessionMode: FMFBenchSessionMode = .cold,
        reasoningLevel: FMFBenchReasoningLevel = .none,
        fallbackMode: FMFBenchFallbackMode = .disabled,
        connectivity: FMFBenchConnectivity = .normal,
        randomizeOrder: Bool = true,
        randomSeed: UInt64 = 20_260_929
    ) {
        self.suite = suite
        self.scenarios = scenarios ?? FMFBenchScenarioCatalog.scenarios(for: suite)
        self.model = model
        self.warmupCount = max(0, warmupCount)
        self.repetitions = max(1, repetitions)
        self.sampleLimit = sampleIDs?.count
            ?? (useAllSamples ? nil : sampleLimit.map { max(1, $0) } ?? suite.defaultSampleLimit)
        self.sampleIDs = sampleIDs
        self.sessionMode = sessionMode
        self.reasoningLevel = reasoningLevel
        self.fallbackMode = fallbackMode
        self.connectivity = connectivity
        self.randomizeOrder = randomizeOrder
        self.randomSeed = randomSeed
    }
}

public actor FMFBenchRunner {
    public enum Error: Swift.Error, LocalizedError, Sendable {
        case onDeviceModelUnavailable(String)
        case privateCloudComputeRequiresXcode27
        case privateCloudComputeUnavailable(String)
        case scenarioRequiresOS27(String)
        case imageFixtureUnavailable
        case emptyResponse
        case offlineConnectivityNotObserved(String)
        case unknownSampleIDs([String])
        case noSamplesSelected

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
                Offline mode requires no active network path, but FMFBench observed \(observation). \
                Disable Wi-Fi and cellular connectivity, then rerun the experiment.
                """
            case .unknownSampleIDs(let sampleIDs):
                "Unknown sample IDs: \(sampleIDs.joined(separator: ", "))."
            case .noSamplesSelected:
                "The configuration did not select any FMFBench samples."
            }
        }
    }

    private struct WorkItem: Sendable {
        let scenario: FMFBenchScenario
        let sample: FMFBenchSample
        let iteration: Int
    }

    private let configuration: FMFBenchRunConfiguration
    private var warmSessions: [String: FMFBenchSessionBundle] = [:]
    private var offlineConnectivityVerified = false

    public init(configuration: FMFBenchRunConfiguration = .init()) {
        self.configuration = configuration
    }

    public func run() async throws -> FMFBenchRunResult {
        let workItems = try workItems()
        offlineConnectivityVerified = try await verifyConnectivity()

        if configuration.model == .onDevice || configuration.fallbackMode == .onDevice {
            try ensureOnDeviceAvailability()
        }

        let startedAt = Date.now
        let environment = EnvironmentSnapshot.capture()
        let quotaBefore = quotaSnapshot()
        let contextSize = await modelContextSize()
        var failures: [FMFBenchFailure] = []

        for index in 0..<configuration.warmupCount {
            do {
                try await warmUp()
            } catch {
                let evidence = error as? FMFBenchExecutionEvidenceError
                failures.append(
                    FMFBenchFailure(
                        scenarioID: "__warmup__",
                        sampleID: "__warmup__-\(index + 1)",
                        iteration: index + 1,
                        kind: evidence?.kind ?? failureKind(error),
                        message: evidence?.message ?? detailedMessage(for: error),
                        toolCalls: evidence?.toolCalls,
                        finalState: evidence?.finalState
                    )
                )
            }
        }

        var trials: [FMFBenchTrialResult] = []
        for item in workItems {
            do {
                trials.append(try await run(item: item, contextSize: contextSize))
            } catch {
                let evidence = error as? FMFBenchExecutionEvidenceError
                failures.append(
                    FMFBenchFailure(
                        scenarioID: item.scenario.id,
                        sampleID: item.sample.id,
                        iteration: item.iteration,
                        kind: evidence?.kind ?? failureKind(error),
                        message: evidence?.message ?? detailedMessage(for: error),
                        toolCalls: evidence?.toolCalls,
                        finalState: evidence?.finalState
                    )
                )
            }
        }

        return FMFBenchRunResult(
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

    private func workItems() throws -> [WorkItem] {
        if let sampleIDs = configuration.sampleIDs {
            let availableSampleIDs = Set(
                configuration.scenarios.flatMap(\.samples).map(\.id)
            )
            let unknownSampleIDs = sampleIDs.subtracting(availableSampleIDs).sorted()
            guard unknownSampleIDs.isEmpty else {
                throw Error.unknownSampleIDs(unknownSampleIDs)
            }
        }

        var items = configuration.scenarios.flatMap { scenario in
            let selectedSamples = configuration.sampleIDs.map { sampleIDs in
                scenario.samples.filter { sampleIDs.contains($0.id) }
            } ?? scenario.samples
            let samples = configuration.sampleLimit.map { Array(selectedSamples.prefix($0)) }
                ?? selectedSamples
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
        guard !items.isEmpty else {
            throw Error.noSamplesSelected
        }
        return items
    }

    private func run(item: WorkItem, contextSize modelContextSize: Int?) async throws
        -> FMFBenchTrialResult {
        let primaryStartedAt = Date.now
        let primaryResource = FMFBenchResourceSnapshot.capture()
        do {
            return try await execute(
                item: item, model: configuration.model, contextSize: modelContextSize)
        } catch {
            if item.sample.safetyExpectation != nil,
                let outcome = FMFBenchSafetyClassifier.outcome(for: error) {
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
            let fallbackResource = FMFBenchResourceSnapshot.capture()
            do {
                return try await execute(
                    item: item,
                    model: .onDevice,
                    contextSize: fallbackContextSize,
                    fallbackReason: fallbackReason
                )
            } catch {
                if item.sample.safetyExpectation != nil,
                    let outcome = FMFBenchSafetyClassifier.outcome(for: error) {
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
        model: FMFBenchModel,
        contextSize: Int?,
        startedAt: Date,
        startingResource: FMFBenchResourceSnapshot,
        fallbackReason: String? = nil,
        outcome: FMFBenchSafetyOutcome,
        error: any Swift.Error
    ) async -> FMFBenchTrialResult {
        let endedAt = Date.now
        let counts = await tokenCounts(
            for: item.scenario,
            sample: item.sample,
            response: "",
            firstStreamUpdate: "",
            model: model
        )
        let metrics = FMFBenchTrialMetrics(
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
        return FMFBenchTrialResult(
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
            grade: FMFBenchGrader.grade(response: "", checks: item.sample.checks),
            metrics: metrics,
            environment: EnvironmentSnapshot.capture()
        )
    }

    private func execute(
        item: WorkItem,
        model: FMFBenchModel,
        contextSize: Int?,
        fallbackReason: String? = nil
    ) async throws -> FMFBenchTrialResult {
        try ensureScenarioAvailability(item.scenario)
        let bundle = try sessionBundle(for: item.scenario, model: model)
        await bundle.recorder.reset()
        await bundle.mockWorld?.reset(for: item.sample.id)
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
        var resources = [FMFBenchResourceSnapshot.capture()]
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
                    where FMFBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
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
        case .guided(let fmfBenchSchema):
            let schema = try FMFBenchSchemaFactory.make(fmfBenchSchema)
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
                    where FMFBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
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
            let transcriptResponse = FMFBenchTranscriptRecovery.latestResponse(
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

        let toolCalls = await bundle.recorder.snapshot()
        let finalState = await bundle.mockWorld?.snapshot()
        guard !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw FMFBenchExecutionEvidenceError(
                kind: "generation",
                message: detailedMessage(for: Error.emptyResponse),
                toolCalls: toolCalls,
                finalState: finalState
            )
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
        let counts = FMFBenchTokenCounts(
            input: usageInputTokens ?? estimatedCounts.input,
            output: usageOutputTokens ?? estimatedCounts.output,
            firstStreamUpdate: usageFirstOutputTokens ?? estimatedCounts.firstStreamUpdate,
            source: usageOutputTokens == nil ? estimatedCounts.source : .sessionUsage
        )
        let safetyOutcome = FMFBenchSafetyClassifier.outcome(
            for: response,
            expectation: item.sample.safetyExpectation
        )
        let metrics = FMFBenchTrialMetrics(
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

        return FMFBenchTrialResult(
            scenario: item.scenario,
            sample: item.sample,
            requestedModel: configuration.model,
            executedModel: model,
            iteration: item.iteration,
            usedFallback: fallbackReason != nil,
            fallbackReason: fallbackReason,
            offlineSuccess: isVerifiedOfflineExecution(model: model),
            toolCalls: toolCalls,
            finalState: finalState,
            safetyOutcome: safetyOutcome,
            response: response,
            grade: FMFBenchGrader.grade(
                response: response,
                checks: item.sample.checks,
                toolCalls: toolCalls,
                finalState: finalState
            ),
            metrics: metrics,
            environment: EnvironmentSnapshot.capture()
        )
    }

    private func sessionBundle(
        for scenario: FMFBenchScenario,
        model: FMFBenchModel
    ) throws -> FMFBenchSessionBundle {
        let key = "\(model.rawValue):\(scenario.id)"
        if configuration.sessionMode == .warm, let existing = warmSessions[key] {
            return existing
        }

        let recorder = FMFBenchToolRecorder()
        let toolRuntime = fmfBenchToolRuntime(for: scenario.toolSet, recorder: recorder)
        let session: LanguageModelSession
        switch model {
        case .onDevice:
            let systemModel = SystemLanguageModel(
                useCase: .general,
                guardrails: .default
            )
            session = LanguageModelSession(
                model: systemModel,
                tools: toolRuntime.tools,
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
                        tools: toolRuntime.tools,
                        instructions: Instructions(scenario.instructions)
                    )
                } else {
                    throw Error.privateCloudComputeRequiresXcode27
                }
            #else
                throw Error.privateCloudComputeRequiresXcode27
            #endif
        }

        let bundle = FMFBenchSessionBundle(
            session: session,
            recorder: recorder,
            mockWorld: toolRuntime.mockWorld
        )
        if configuration.sessionMode == .warm {
            warmSessions[key] = bundle
        }
        return bundle
    }

    private func warmUp() async throws {
        let scenario = FMFBenchScenario(
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
        let observation = await FMFBenchConnectivityObserver.observe()
        guard observation.verifiesOfflineExperiment else {
            throw Error.offlineConnectivityNotObserved(observation.displayName)
        }
        return true
    }

    private func isVerifiedOfflineExecution(model: FMFBenchModel) -> Bool {
        FMFBenchOfflineResultPolicy.isSuccess(
            connectivityVerified: offlineConnectivityVerified,
            model: model
        )
    }

    private func ensureScenarioAvailability(_ scenario: FMFBenchScenario) throws {
        guard scenario.requiresOS27 else { return }
        #if compiler(>=6.4)
            guard #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) else {
                throw Error.scenarioRequiresOS27(scenario.title)
            }
        #else
            throw Error.scenarioRequiresOS27(scenario.title)
        #endif
    }

    private func makePrompt(for sample: FMFBenchSample) throws -> Prompt {
        guard sample.visualFixture != nil else {
            return Prompt(sample.prompt)
        }
        #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                return try fmfBenchPrompt(for: sample)
            }
        #endif
        throw Error.imageFixtureUnavailable
    }

    private func modelContextSize() async -> Int? {
        await contextSize(for: configuration.model)
    }

    private func contextSize(for model: FMFBenchModel) async -> Int? {
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

    private func quotaSnapshot() -> FMFBenchQuotaSnapshot? {
        guard configuration.model == .privateCloudCompute else { return nil }
        #if compiler(>=6.4)
            if #available(macOS 27.0, iOS 27.0, visionOS 27.0, *) {
                let usage = PrivateCloudComputeLanguageModel().quotaUsage
                switch usage.status {
                case .belowLimit(let detail):
                    return FMFBenchQuotaSnapshot(
                        status: "belowLimit",
                        isApproachingLimit: detail.isApproachingLimit,
                        isLimitReached: usage.isLimitReached,
                        resetDate: usage.resetDate
                    )
                case .limitReached:
                    return FMFBenchQuotaSnapshot(
                        status: "limitReached",
                        isApproachingLimit: nil,
                        isLimitReached: usage.isLimitReached,
                        resetDate: usage.resetDate
                    )
                @unknown default:
                    return FMFBenchQuotaSnapshot(
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
    resources: inout [FMFBenchResourceSnapshot]
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
    where FMFBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
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
    resources: inout [FMFBenchResourceSnapshot]
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
    where FMFBenchPartialResponsePolicy.shouldPreserve(response, after: error) {
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

private struct FMFBenchExecutionEvidenceError: Swift.Error, LocalizedError, Sendable {
    let kind: String
    let message: String
    let toolCalls: [FMFBenchToolCall]
    let finalState: FMFBenchStateSnapshot?

    var errorDescription: String? { message }
}

private func failureKind(_ error: any Swift.Error) -> String {
    if FMFBenchSafetyClassifier.outcome(for: error) == .guardrailViolation {
        return "guardrail"
    }
    if FMFBenchSafetyClassifier.outcome(for: error) == .refusal {
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
        for model: FMFBenchModel,
        reasoningLevel: FMFBenchReasoningLevel,
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
