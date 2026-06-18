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
    @State private var currentPrompt = "Explain how Foundation Models reports token usage in two short paragraphs."
    @State private var report: UsagePerformanceReport?
    @State private var isRunning = false
    @State private var errorMessage: String?
    @State private var runID = UUID()

    var body: some View {
        ExampleViewBase(
            title: "Response Usage",
            description: "Run a real streamed response and inspect its reported usage",
            defaultPrompt: "Explain how Foundation Models reports token usage in two short paragraphs.",
            currentPrompt: $currentPrompt,
            isRunning: isRunning,
            errorMessage: errorMessage,
            codeExample: codeExample,
            onRun: runTrace,
            onReset: reset
        ) {
            VStack(spacing: Spacing.large) {
                if let report {
                    Xcode27Section("Framework-Reported Usage") {
                        Xcode27KeyValueList(items: [
                            ("Input", tokenLabel(report.inputTokens)),
                            ("Cached input", tokenLabel(report.cachedInputTokens)),
                            ("Output", tokenLabel(report.outputTokens)),
                            ("Reasoning output", tokenLabel(report.reasoningTokens)),
                            ("Total", tokenLabel(report.totalTokens))
                        ])
                    }

                    Xcode27Section("App-Observed Timing") {
                        Xcode27KeyValueList(items: [
                            ("First stream update", durationLabel(report.timeToFirstUpdate)),
                            ("End to end", durationLabel(report.totalDuration))
                        ])
                    }

                    Xcode27Section("Response") {
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

                Xcode27Section("What These Numbers Mean") {
                    Text(
                        "Token counts come from LanguageModelSession.Response.Usage. Timing is measured by this app with " +
                        "ContinuousClock; Foundation Models does not attribute latency to prompts, tools, caching, or reasoning."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func runTrace() {
        let id = UUID()
        runID = id
        isRunning = true
        errorMessage = nil
        report = nil

        Task { @MainActor in
            defer {
                if runID == id {
                    isRunning = false
                }
            }

            #if compiler(>=6.4)
            guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else {
                guard runID == id else { return }
                errorMessage = "Response usage requires an OS 27 runtime."
                return
            }

            do {
                let session = LanguageModelSession()
                let clock = ContinuousClock()
                let startedAt = clock.now
                var firstUpdateAt: ContinuousClock.Instant?
                let stream = session.streamResponse(
                    to: currentPrompt,
                    contextOptions: ContextOptions(reasoningLevel: .moderate),
                    metadata: ["example": "response-usage"]
                )

                for try await _ in stream where firstUpdateAt == nil {
                    firstUpdateAt = clock.now
                }

                let response = try await stream.collect()
                let finishedAt = clock.now
                guard runID == id else { return }

                report = UsagePerformanceReport(
                    response: response.content,
                    inputTokens: response.usage.input.totalTokenCount,
                    cachedInputTokens: response.usage.input.cachedTokenCount,
                    outputTokens: response.usage.output.totalTokenCount,
                    reasoningTokens: response.usage.output.reasoningTokenCount,
                    totalTokens: response.usage.totalTokenCount,
                    timeToFirstUpdate: firstUpdateAt.map { startedAt.duration(to: $0) },
                    totalDuration: startedAt.duration(to: finishedAt)
                )
            } catch {
                guard runID == id else { return }
                errorMessage = error.localizedDescription
            }
            #else
            guard runID == id else { return }
            errorMessage = "Response usage requires the Xcode 27 SDK."
            #endif
        }
    }

    private func reset() {
        runID = UUID()
        isRunning = false
        currentPrompt = ""
        report = nil
        errorMessage = nil
    }

    private func tokenLabel(_ count: Int) -> String {
        count.formatted() + (count == 1 ? " token" : " tokens")
    }

    private func durationLabel(_ duration: Duration?) -> String {
        guard let duration else { return "No update received" }
        let components = duration.components
        let seconds = Double(components.seconds) + Double(components.attoseconds) / 1e18
        return seconds.formatted(.number.precision(.fractionLength(2))) + " s"
    }

    private var codeExample: String {
        """
        let clock = ContinuousClock()
        let startedAt = clock.now
        var firstUpdateAt: ContinuousClock.Instant?
        let stream = session.streamResponse(to: prompt)

        for try await _ in stream {
            firstUpdateAt = firstUpdateAt ?? clock.now
        }

        let response = try await stream.collect()
        print(response.usage.input.totalTokenCount)
        print(response.usage.input.cachedTokenCount)
        print(response.usage.output.totalTokenCount)
        print(response.usage.output.reasoningTokenCount)
        print(startedAt.duration(to: firstUpdateAt ?? clock.now))
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
