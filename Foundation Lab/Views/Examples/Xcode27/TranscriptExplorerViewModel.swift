//
//  TranscriptExplorerViewModel.swift
//  FoundationLab
//

import Foundation
import Observation

@MainActor
@Observable
final class TranscriptExplorerViewModel {
    static let defaultPrompt = "Use the fact tool with the transcript topic, then explain what a session transcript records."

    var prompt = defaultPrompt
    var entries: [SessionTranscriptSnapshot.Entry] = []
    var selectedEntryID: String?
    var selectedSegmentID: String?
    var errorMessage: String?
    var isRunning = false

    private var activeRunID: UUID?

    var selectedEntry: SessionTranscriptSnapshot.Entry? {
        entries.first { $0.id == selectedEntryID }
    }

    var selectedSegment: SessionTranscriptSnapshot.Segment? {
        selectedEntry?.segments.first { $0.id == selectedSegmentID }
    }

    func run() async {
        guard let capturedPrompt = promptForNewRun else { return }

        let runID = UUID()
        activeRunID = runID
        isRunning = true
        entries = []
        selectedEntryID = nil
        selectedSegmentID = nil
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
            errorMessage = String(localized: "Live reasoning and segment inspection requires an OS 27 runtime.")
            return
        }

        do {
            try Task.checkCancellation()
            let snapshot = try await SessionObservabilityRunner.run(
                prompt: capturedPrompt,
                labIdentifier: "transcript-explorer",
                requestsReasoning: true
            )
            try Task.checkCancellation()
            guard activeRunID == runID else { return }
            guard prompt.trimmingCharacters(in: .whitespacesAndNewlines) == capturedPrompt else {
                errorMessage = String(
                    localized: "The prompt changed while the session was running. Run it again to inspect matching results."
                )
                return
            }
            entries = snapshot.entries
            selectEntry(snapshot.entries.first?.id)
        } catch is CancellationError {
            return
        } catch {
            guard activeRunID == runID else { return }
            errorMessage = error.localizedDescription
        }
        #else
        guard activeRunID == runID else { return }
        errorMessage = String(localized: "Live transcript inspection requires the Xcode 27 SDK.")
        #endif
    }

    func selectEntry(_ id: String?) {
        selectedEntryID = id
        selectedSegmentID = entries.first { $0.id == id }?.segments.first?.id
    }

    func selectSegment(_ id: String?) {
        selectedSegmentID = id
    }

    func reset() {
        activeRunID = nil
        prompt = Self.defaultPrompt
        entries = []
        selectedEntryID = nil
        selectedSegmentID = nil
        errorMessage = nil
        isRunning = false
    }

    private var promptForNewRun: String? {
        guard !Task.isCancelled else { return nil }
        let value = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
