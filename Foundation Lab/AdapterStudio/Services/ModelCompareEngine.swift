#if os(macOS)
import Foundation
import FoundationModels
import OSLog

@MainActor
final class ModelCompareEngine {
    private enum RunOutcome: Sendable {
        case success(ModelCompareResponseSummary)
        case failure(ModelCompareError)
        case availability(SystemLanguageModel.Availability)
        case skipped
        case cancelled
    }

    private struct StreamRequest: Sendable {
        let prompt: String
        let options: GenerationOptions
        let continuation: AsyncStream<ModelCompareEvent>.Continuation
    }

    private struct ActiveRun {
        let id: UUID
        let task: Task<Void, Never>
        let continuation: AsyncStream<ModelCompareEvent>.Continuation
    }

    private struct ComparisonSummaries {
        var base: ModelCompareResponseSummary?
        var adapter: ModelCompareResponseSummary?

        mutating func set(
            _ summary: ModelCompareResponseSummary?,
            for source: ModelCompareSource
        ) {
            switch source {
            case .base:
                base = summary
            case .adapter:
                adapter = summary
            }
        }
    }

    private let logger = Logger(
        subsystem: "com.rudrankriyam.foundationlab",
        category: "AdapterComparison"
    )
    private let baseModel: SystemLanguageModel
    private var adapterModel: SystemLanguageModel?
    private var activeRun: ActiveRun?

    init(model: SystemLanguageModel = .default) {
        baseModel = model
    }

    func cancelCurrentRun() {
        guard let activeRun else { return }

        self.activeRun = nil
        activeRun.task.cancel()
        activeRun.continuation.finish()
    }

    func configureAdapter(_ context: AdapterContext?) {
        cancelCurrentRun()
        adapterModel = context.map { SystemLanguageModel(adapter: $0.adapter) }
    }

    func submit(
        prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncStream<ModelCompareEvent> {
        cancelCurrentRun()

        return AsyncStream { continuation in
            continuation.yield(.started(prompt: prompt))

            let runID = UUID()
            let runTask = Task { [weak self] in
                guard let self else { return }
                await self.runComparison(
                    prompt: prompt,
                    options: options,
                    continuation: continuation,
                    runID: runID
                )
            }
            activeRun = ActiveRun(
                id: runID,
                task: runTask,
                continuation: continuation
            )

            continuation.onTermination = { @Sendable [weak self, runTask, runID] _ in
                runTask.cancel()
                Task { @MainActor [weak self] in
                    self?.clearCurrentRun(ifMatching: runID)
                }
            }
        }
    }
}

private extension ModelCompareEngine {
    private func runComparison(
        prompt: String,
        options: GenerationOptions,
        continuation: AsyncStream<ModelCompareEvent>.Continuation,
        runID: UUID
    ) async {
        defer {
            continuation.finish()
            clearCurrentRun(ifMatching: runID)
        }

        let summaries = await collectSummaries(
            prompt: prompt,
            options: options,
            continuation: continuation
        )

        guard !Task.isCancelled, activeRun?.id == runID else { return }

        if summaries.base != nil || summaries.adapter != nil {
            continuation.yield(
                .finished(
                    ModelCompareResult(
                        prompt: prompt,
                        base: summaries.base,
                        adapter: summaries.adapter
                    )
                )
            )
        }
    }

    private func collectSummaries(
        prompt: String,
        options: GenerationOptions,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) async -> ComparisonSummaries {
        let request = StreamRequest(
            prompt: prompt,
            options: options,
            continuation: continuation
        )
        var summaries = ComparisonSummaries()

        await withTaskGroup(
            of: (ModelCompareSource, RunOutcome).self
        ) { group in
            addComparisonTasks(to: &group, request: request)

            for await (source, outcome) in group {
                summaries.set(
                    processOutcome(
                        outcome,
                        for: source,
                        continuation: continuation
                    ),
                    for: source
                )
            }
        }

        return summaries
    }

    private func clearCurrentRun(ifMatching runID: UUID) {
        guard activeRun?.id == runID else { return }
        activeRun = nil
    }

    private func addComparisonTasks(
        to group: inout TaskGroup<(ModelCompareSource, RunOutcome)>,
        request: StreamRequest
    ) {
        let baseModel = baseModel
        group.addTask { [self, baseModel, request] in
            let outcome = await self.streamModel(
                source: .base,
                model: baseModel,
                request: request
            )
            return (.base, outcome)
        }

        guard let adapterModel else { return }

        group.addTask { [self, adapterModel, request] in
            let outcome = await self.streamModel(
                source: .adapter,
                model: adapterModel,
                request: request
            )
            return (.adapter, outcome)
        }
    }

    private func processOutcome(
        _ outcome: RunOutcome,
        for source: ModelCompareSource,
        continuation: AsyncStream<ModelCompareEvent>.Continuation
    ) -> ModelCompareResponseSummary? {
        switch outcome {
        case .success(let summary):
            return summary
        case .failure(let error):
            continuation.yield(.failed(source: source, error: error))
            return nil
        case .availability(let availability):
            continuation.yield(.availabilityIssue(source: source, status: availability))
            return nil
        case .skipped:
            logger.info("Skipped \(source.displayName, privacy: .public); no model was configured.")
            return nil
        case .cancelled:
            logger.debug("Cancelled \(source.displayName, privacy: .public) comparison.")
            return nil
        }
    }

    private func streamModel(
        source: ModelCompareSource,
        model: SystemLanguageModel,
        request: StreamRequest
    ) async -> RunOutcome {
        let availability = model.availability
        guard availability == .available else {
            let availabilityDescription = String(describing: availability)
            logger.error(
                "Model unavailable for \(source.displayName, privacy: .public): \(availabilityDescription, privacy: .public)"
            )
            return .availability(availability)
        }

        var metrics = ModelCompareResponseMetrics(startedAt: .now)
        let session = LanguageModelSession(model: model)

        do {
            let stream = session.streamResponse(
                to: request.prompt,
                options: request.options
            )
            var latestContent = ""

            for try await snapshot in stream {
                guard !Task.isCancelled else { return .cancelled }

                metrics.markFirstToken()
                latestContent = renderPartialText(from: snapshot)
                request.continuation.yield(
                    .token(
                        source: source,
                        text: latestContent,
                        metrics: metrics
                    )
                )
            }

            guard !Task.isCancelled else { return .cancelled }

            metrics.markCompleted()
            return .success(
                ModelCompareResponseSummary(
                    source: source,
                    text: latestContent,
                    metrics: metrics
                )
            )
        } catch {
            guard !Task.isCancelled else { return .cancelled }

            let errorDescription = error.localizedDescription
            logger.error(
                "Streaming failed for \(source.displayName, privacy: .public): \(errorDescription, privacy: .public)"
            )
            return .failure(ModelCompareError(message: errorDescription))
        }
    }

    private func renderPartialText(
        from snapshot: LanguageModelSession.ResponseStream<String>.Snapshot
    ) -> String {
        if let value = try? snapshot.rawContent.value(String.self) {
            return value
        }

        let json = snapshot.rawContent.jsonString
        if let data = json.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(String.self, from: data) {
            return decoded
        }

        return json
    }
}
#endif
