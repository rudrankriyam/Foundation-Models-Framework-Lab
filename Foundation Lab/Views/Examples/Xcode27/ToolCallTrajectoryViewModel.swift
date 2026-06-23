//
//  ToolCallTrajectoryViewModel.swift
//  FoundationLab
//

import Foundation
import FoundationLabCore
import FoundationModels
import Observation

@MainActor
@Observable
final class ToolCallTrajectoryViewModel {
    static let defaultPrompt = "Call readFoundationLabFact exactly once with the transcript topic, then answer in one sentence."
    static let forbiddenToolNames: Set<String> = ["deleteItem", "sendMessage"]

    var prompt = defaultPrompt
    var observedEvents: [SessionTranscriptSnapshot.ToolEvent] = []
    var response: String?
    var evaluation: FoundationLabToolTrajectoryEvaluation?
    var errorMessage: String?
    var isRunning = false

    let expectedCalls: [FoundationLabToolTrajectoryEvaluation.Call]

    private var activeRunID: UUID?

    init() {
        let arguments = FoundationLabSessionObservabilityTool.Arguments(topic: .transcript)
        self.expectedCalls = [
            FoundationLabToolTrajectoryEvaluation.Call(
                id: "expected-1",
                name: FoundationLabSessionObservabilityTool().name,
                arguments: arguments.generatedContent.jsonString
            )
        ]
    }

    func run() async {
        guard let capturedPrompt = promptForNewRun else { return }

        let runID = UUID()
        activeRunID = runID
        isRunning = true
        observedEvents = []
        response = nil
        evaluation = nil
        errorMessage = nil

        defer {
            if activeRunID == runID {
                activeRunID = nil
                isRunning = false
            }
        }

        #if compiler(>=6.4)
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) else {
            guard activeRunID == runID else { return }
            errorMessage = String(localized: "Live trajectory capture requires an OS 27 runtime.")
            return
        }

        do {
            try Task.checkCancellation()
            let snapshot = try await SessionObservabilityRunner.run(
                prompt: capturedPrompt,
                labIdentifier: "tool-trajectory"
            )
            try Task.checkCancellation()
            guard activeRunID == runID else { return }
            guard prompt.trimmingCharacters(in: .whitespacesAndNewlines) == capturedPrompt else {
                errorMessage = String(
                    localized: "The prompt changed while the session was running. Run it again to inspect matching results."
                )
                return
            }

            observedEvents = snapshot.toolEvents
            response = snapshot.entries.last(where: { $0.kind == .response })?.segments
                .map(\.content)
                .filter { !$0.isEmpty }
                .joined(separator: "\n\n")
            evaluation = FoundationLabToolTrajectoryEvaluation(
                expected: expectedCalls,
                observed: snapshot.toolCalls,
                forbiddenToolNames: Self.forbiddenToolNames
            )
        } catch is CancellationError {
            return
        } catch {
            guard activeRunID == runID else { return }
            errorMessage = error.localizedDescription
        }
        #else
        guard activeRunID == runID else { return }
        errorMessage = String(localized: "Live trajectory capture requires the Xcode 27 SDK.")
        #endif
    }

    func reset() {
        activeRunID = nil
        prompt = Self.defaultPrompt
        observedEvents = []
        response = nil
        evaluation = nil
        errorMessage = nil
        isRunning = false
    }

    private var promptForNewRun: String? {
        guard !Task.isCancelled else { return nil }
        let value = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
