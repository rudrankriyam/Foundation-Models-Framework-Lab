//
//  TranscriptExplorerView.swift
//  FoundationLab
//

import SwiftUI

struct TranscriptExplorerView: View {
    @State private var model = TranscriptExplorerViewModel()

    var body: some View {
        @Bindable var model = model

        ExampleViewBase(
            title: String(localized: "Transcript Explorer"),
            description: String(localized: "Run a real session and inspect the transcript entries it actually emits"),
            currentPrompt: $model.prompt,
            isRunning: model.isRunning,
            errorMessage: model.errorMessage,
            codeExample: Self.codeExample,
            runLabel: String(localized: "Run Session"),
            onRun: model.run,
            onReset: model.reset
        ) {
            VStack(spacing: Spacing.large) {
                if model.entries.isEmpty {
                    ContentUnavailableView {
                        Label(
                            model.isRunning ? "Session Running" : "No Transcript Yet",
                            systemImage: model.isRunning ? "ellipsis" : "list.bullet.rectangle.portrait"
                        )
                    } description: {
                        Text(
                            model.isRunning
                                ? "The transcript will appear after the model finishes or the run is cancelled."
                                : "Run the prompt to create a session. Only entries captured from that session will appear here."
                        )
                    }
                } else {
                    TranscriptEntryBrowserView(
                        entries: model.entries,
                        selectedEntryID: model.selectedEntryID,
                        onSelect: model.selectEntry
                    )

                    if let selectedEntry = model.selectedEntry {
                        TranscriptEntryDetailView(
                            entry: selectedEntry,
                            selectedSegmentID: $model.selectedSegmentID
                        )
                    }
                }

                Xcode27Section(String(localized: "Observation Boundary")) {
                    Text(
                        String(
                            localized: """
                            Entry and segment labels are derived from session.transcript after this run. If the active model does not \
                            emit reasoning, attachments, custom content, or a tool event, the lab does not manufacture one.
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

    private static let codeExample = """
    let session = LanguageModelSession(profile: SessionObservabilityProfile())
    _ = try await session.respond(to: prompt)

    for entry in session.transcript {
        switch entry {
        case .instructions(let instructions):
            inspect(instructions.segments)
        case .prompt(let prompt):
            inspect(prompt.segments)
        case .reasoning(let reasoning):
            inspect(reasoning.segments)
        case .toolCalls(let calls):
            calls.forEach { inspect($0.toolName, $0.arguments) }
        case .toolOutput(let output):
            inspect(output.toolName, output.segments)
        case .response(let response):
            inspect(response.segments)
        @unknown default:
            inspectUnknown(entry)
        }
    }
    """
}

#Preview {
    NavigationStack {
        TranscriptExplorerView()
    }
}
