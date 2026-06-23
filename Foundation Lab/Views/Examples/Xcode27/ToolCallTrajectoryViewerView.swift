//
//  ToolCallTrajectoryViewerView.swift
//  FoundationLab
//

import SwiftUI

struct ToolCallTrajectoryViewerView: View {
    @State private var model = ToolCallTrajectoryViewModel()

    var body: some View {
        @Bindable var model = model

        ExampleViewBase(
            title: String(localized: "Tool Trajectories"),
            description: String(localized: "Run a real tool turn and compare transcript evidence with an authored expectation"),
            currentPrompt: $model.prompt,
            isRunning: model.isRunning,
            errorMessage: model.errorMessage,
            codeExample: Self.codeExample,
            runLabel: String(localized: "Run Trajectory"),
            onRun: model.run,
            onReset: model.reset
        ) {
            if let evaluation = model.evaluation {
                ToolTrajectoryResultView(
                    evaluation: evaluation,
                    observedEvents: model.observedEvents,
                    response: model.response,
                    forbiddenToolNames: ToolCallTrajectoryViewModel.forbiddenToolNames
                )
            } else {
                ContentUnavailableView {
                    Label(
                        model.isRunning ? "Tool Turn Running" : "No Observed Trajectory",
                        systemImage: model.isRunning ? "ellipsis" : "point.topleft.down.to.point.bottomright.curvepath"
                    )
                } description: {
                    Text(
                        model.isRunning
                            ? "The path will appear after the session finishes or the run is cancelled."
                            : "Run the prompt to capture ordered tool calls and outputs from session.transcript."
                    )
                }
            }
        }
    }

    private static let codeExample = """
    let session = LanguageModelSession(profile: SessionObservabilityProfile())
    _ = try await session.respond(to: prompt)

    let observedCalls = session.transcript.flatMap { entry -> [Transcript.ToolCall] in
        guard case .toolCalls(let calls) = entry else { return [] }
        return Array(calls)
    }

    // Compare observed names, canonical arguments, and order with an
    // expectation declared by your app or test. Never score authored
    // fixtures as though they came from this session.
    """
}

#Preview {
    NavigationStack {
        ToolCallTrajectoryViewerView()
    }
}
