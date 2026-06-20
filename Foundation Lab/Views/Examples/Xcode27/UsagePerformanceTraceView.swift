//
//  UsagePerformanceTraceView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import Foundation
import FoundationModels
import SwiftUI

struct UsagePerformanceTraceView: View {
    private static let defaultPrompt = "Explain how Foundation Models reports token usage in two short paragraphs."

    @State private var currentPrompt = defaultPrompt
    @State private var report: UsagePerformanceReport?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var runID = UUID()

    var body: some View {
        ExampleViewBase(
            title: String(localized: "Response Usage"),
            description: String(localized: "Run a real streamed response and inspect its reported usage"),
            currentPrompt: $currentPrompt,
            isRunning: isRunning,
            errorMessage: errorMessage,
            codeExample: codeExample,
            onRun: runTrace,
            onReset: reset
        ) {
            VStack(spacing: Spacing.large) {
                if let report {
                    Xcode27Section(String(localized: "Framework-Reported Usage")) {
                        Xcode27KeyValueList(items: [
                            (String(localized: "Input"), tokenLabel(report.inputTokens)),
                            (String(localized: "Cached input"), tokenLabel(report.cachedInputTokens)),
                            (String(localized: "Output"), tokenLabel(report.outputTokens)),
                            (String(localized: "Reasoning output"), tokenLabel(report.reasoningTokens)),
                            (String(localized: "Total"), tokenLabel(report.totalTokens))
                        ])
                    }

                    Xcode27Section(String(localized: "App-Observed Timing")) {
                        Xcode27KeyValueList(items: [
                            (String(localized: "First stream update"), durationLabel(report.timeToFirstUpdate)),
                            (String(localized: "End to end"), durationLabel(report.totalDuration))
                        ])
                    }

                    Xcode27Section(String(localized: "Response")) {
                        Text(report.response)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No Response Measured", systemImage: "waveform.path.ecg")
                    } description: {
                        Text("Run the prompt to create a new session, stream one response, and read that response's actual usage.")
                    }
                }

                Xcode27Section(String(localized: "What These Numbers Mean")) {
                    Text(
                        String(
                            localized: """
                            Token counts come from LanguageModelSession.Response.Usage. Timing is measured by this app with \
                            ContinuousClock; Foundation Models does not attribute latency to prompts, tools, caching, or reasoning.
                            """
                        )
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func runTrace() async {
        let id = UUID()
        let prompt = currentPrompt
        runID = id
        isRunning = true
        errorMessage = nil
        report = nil

        defer {
            if runID == id {
                isRunning = false
            }
        }

        #if compiler(>=6.4)
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else {
            guard runID == id else { return }
            errorMessage = String(localized: "Response usage requires an OS 27 runtime.")
            return
        }

        do {
            let session = LanguageModelSession()
            let clock = ContinuousClock()
            let startedAt = clock.now
            var firstUpdateAt: ContinuousClock.Instant?
            let stream = session.streamResponse(
                to: prompt,
                contextOptions: traceContextOptions(),
                metadata: ["example": "response-usage"]
            )
            var lastSnapshot: LanguageModelSession.ResponseStream<String>.Snapshot?

            for try await snapshot in stream {
                if firstUpdateAt == nil {
                    firstUpdateAt = clock.now
                }
                lastSnapshot = snapshot
            }

            try Task.checkCancellation()
            let finishedAt = clock.now
            guard runID == id, currentPrompt == prompt else { return }
            finishTrace(
                snapshot: lastSnapshot,
                startedAt: startedAt,
                firstUpdateAt: firstUpdateAt,
                finishedAt: finishedAt
            )
        } catch is CancellationError {
            return
        } catch {
            guard runID == id, currentPrompt == prompt else { return }
            errorMessage = error.localizedDescription
        }
        #else
        guard runID == id else { return }
        errorMessage = String(localized: "Response usage requires the Xcode 27 SDK.")
        #endif
    }

    private func reset() {
        runID = UUID()
        isRunning = false
        currentPrompt = Self.defaultPrompt
        report = nil
        errorMessage = nil
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    private func traceContextOptions() -> ContextOptions {
        let supportsReasoning = SystemLanguageModel.default.capabilities.contains(.reasoning)
        return supportsReasoning
            ? ContextOptions(reasoningLevel: .moderate)
            : ContextOptions()
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
    private func finishTrace(
        snapshot: LanguageModelSession.ResponseStream<String>.Snapshot?,
        startedAt: ContinuousClock.Instant,
        firstUpdateAt: ContinuousClock.Instant?,
        finishedAt: ContinuousClock.Instant
    ) {
        guard let snapshot else {
            errorMessage = String(localized: "No update received")
            return
        }

        report = UsagePerformanceReport(
            response: snapshot.content,
            inputTokens: snapshot.usage.input.totalTokenCount,
            cachedInputTokens: snapshot.usage.input.cachedTokenCount,
            outputTokens: snapshot.usage.output.totalTokenCount,
            reasoningTokens: snapshot.usage.output.reasoningTokenCount,
            totalTokens: snapshot.usage.totalTokenCount,
            timeToFirstUpdate: firstUpdateAt.map { startedAt.duration(to: $0) },
            totalDuration: startedAt.duration(to: finishedAt)
        )
    }
    #endif

    private func tokenLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "\(count) token") : String(localized: "\(count) tokens")
    }

    private func durationLabel(_ duration: Duration?) -> String {
        guard let duration else { return String(localized: "No update received") }
        let components = duration.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return String(localized: "\(seconds.formatted(.number.precision(.fractionLength(2)))) s")
    }

    private var codeExample: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let clock = ContinuousClock()
            let startedAt = clock.now
            var firstUpdateAt: ContinuousClock.Instant?
            let stream = session.streamResponse(to: prompt)

            var lastSnapshot: LanguageModelSession.ResponseStream<String>.Snapshot?
            for try await snapshot in stream {
                firstUpdateAt = firstUpdateAt ?? clock.now
                lastSnapshot = snapshot
            }

            if let lastSnapshot {
                print(lastSnapshot.usage.input.totalTokenCount)
                print(lastSnapshot.usage.input.cachedTokenCount)
                print(lastSnapshot.usage.output.totalTokenCount)
                print(lastSnapshot.usage.output.reasoningTokenCount)
            }
            print(startedAt.duration(to: firstUpdateAt ?? clock.now))
        }
        """
    }
}

private struct UsagePerformanceReport {
    let response: String
    let inputTokens: Int
    let cachedInputTokens: Int
    let outputTokens: Int
    let reasoningTokens: Int
    let totalTokens: Int
    let timeToFirstUpdate: Duration?
    let totalDuration: Duration
}

#Preview {
    NavigationStack {
        UsagePerformanceTraceView()
    }
}
