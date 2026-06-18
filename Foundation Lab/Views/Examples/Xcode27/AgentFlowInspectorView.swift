//
//  AgentFlowInspectorView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct AgentFlowInspectorView: View {
    @State private var selectedPhase = AgentTurnPhase.profile

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text(
                    "Foundation Models does not expose a generic agent dashboard. An agentic turn is built from profiles, sessions, " +
                    "tools, transcript entries, and app-owned policy. Inspect live timing and token behavior with Instruments."
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                Xcode27Section("Framework map") {
                    VStack(spacing: 0) {
                        ForEach(AgentTurnPhase.allCases) { phase in
                            Button {
                                selectedPhase = phase
                            } label: {
                                AgentTurnPhaseRow(phase: phase, isSelected: phase == selectedPhase)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(phase == selectedPhase ? .isSelected : [])

                            if phase != AgentTurnPhase.allCases.last {
                                Divider()
                            }
                        }
                    }
                }

                Xcode27Section(selectedPhase.title) {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Text(selectedPhase.detail)
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Xcode27KeyValueList(items: selectedPhase.facts)
                    }
                }

                Xcode27Section("Ownership boundary") {
                    Xcode27KeyValueList(items: [
                        ("Framework", "Profiles, generation, transcript"),
                        ("Your app", "Routing, permissions, confirmation"),
                        ("Evaluator", "Quality and regression checks"),
                        ("Instruments", "Tokens, latency, control flow")
                    ])
                }

                CodeDisclosure(code: selectedPhase.code)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle("Agent Turn Map")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Know which layer owns each decision")
        #endif
    }
}

private struct AgentTurnPhaseRow: View {
    let phase: AgentTurnPhase
    let isSelected: Bool

    var body: some View {
        HStack(spacing: Spacing.medium) {
            Image(systemName: phase.icon)
                .foregroundStyle(phase.tint)
                .frame(width: 28)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(phase.title)
                    .font(.subheadline)
                    .bold()
                Text(phase.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.small)

            Image(systemName: isSelected ? "checkmark" : "chevron.right")
                .foregroundStyle(isSelected ? phase.tint : .secondary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.vertical, Spacing.small)
        .contentShape(.rect)
    }
}

private enum AgentTurnPhase: String, CaseIterable, Identifiable {
    case profile
    case generation
    case tools
    case transcript
    case instruments

    var id: String { rawValue }

    var title: String {
        switch self {
        case .profile: "Dynamic profile"
        case .generation: "Session request"
        case .tools: "Tool lifecycle"
        case .transcript: "Transcript"
        case .instruments: "Runtime trace"
        }
    }

    var summary: String {
        switch self {
        case .profile: "Select instructions, tools, model, and options"
        case .generation: "Generate through LanguageModelSession"
        case .tools: "Observe calls and outputs around app code"
        case .transcript: "Read the linear history of the session"
        case .instruments: "Measure live latency, tokens, and control flow"
        }
    }

    var detail: String {
        switch self {
        case .profile:
            """
            LanguageModelSession.Profile binds dynamic instructions to session configuration. DynamicProfile can change that \
            configuration from app state before requests.
            """
        case .generation:
            """
            LanguageModelSession owns the interaction with a LanguageModel. Respond and streamResponse are the generation boundary; \
            GenerationOptions and ContextOptions configure a request.
            """
        case .tools:
            """
            A Tool exposes app code to the model. Tool-calling mode controls whether tools are allowed, required, or disallowed. \
            Profile lifecycle callbacks observe calls and outputs; your app still owns authorization and side-effect policy.
            """
        case .transcript:
            """
            The transcript is the inspectable session history. It contains instructions, prompts, responses, tool calls, and tool \
            outputs. It does not promise fabricated cache or latency fields.
            """
        case .instruments:
            """
            Use the Foundation Models Instrument to inspect live prompts, response timing, token consumption, tool activity, and control \
            flow. Those measurements come from a recorded trace, not a SwiftUI sample screen.
            """
        }
    }

    var facts: [(String, String)] {
        switch self {
        case .profile:
            [
                ("API", "DynamicProfile"),
                ("Concrete type", "Profile"),
                ("Content", "DynamicInstructions"),
                ("Re-evaluates", "From app state")
            ]
        case .generation:
            [
                ("API", "LanguageModelSession"),
                ("Model", "Any LanguageModel"),
                ("One shot", "respond"),
                ("Streaming", "streamResponse")
            ]
        case .tools:
            [
                ("API", "Tool"),
                ("Modes", "Allowed, required, disallowed"),
                ("Before call", "onToolCall"),
                ("After output", "onToolOutput")
            ]
        case .transcript:
            [
                ("API", "Transcript"),
                ("Order", "Linear entries"),
                ("Includes", "Calls and outputs"),
                ("Use", "History and diagnostics")
            ]
        case .instruments:
            [
                ("Tool", "Foundation Models Instrument"),
                ("Source", "Recorded runtime trace"),
                ("Shows", "Timing and token use"),
                ("Use", "Debug and optimize")
            ]
        }
    }

    var icon: String {
        switch self {
        case .profile: "slider.horizontal.3"
        case .generation: "text.bubble"
        case .tools: "hammer"
        case .transcript: "list.bullet.rectangle"
        case .instruments: "gauge.with.dots.needle.67percent"
        }
    }

    var tint: Color {
        switch self {
        case .profile: .blue
        case .generation: .indigo
        case .tools: .orange
        case .transcript: .green
        case .instruments: .purple
        }
    }

    var code: String {
        switch self {
        case .profile:
            """
            let profile = LanguageModelSession.Profile {
                DynamicInstructions("Help with the current task.")
                SearchTool()
            }
            .model(SystemLanguageModel.default)
            .toolCallingMode(.allowed)

            let session = LanguageModelSession(profile: profile)
            """
        case .generation:
            """
            let session = LanguageModelSession()
            let response = try await session.respond(to: prompt)

            for try await snapshot in session.streamResponse(to: prompt) {
                // Render the latest snapshot.
            }
            """
        case .tools:
            """
            LanguageModelSession.Profile {
                SearchTool()
            }
            .toolCallingMode(.allowed)
            .onToolCall { call in
                // Log or apply app-owned authorization policy.
            }
            .onToolOutput { call, output in
                // Record the observed output.
            }
            """
        case .transcript:
            """
            for entry in session.transcript {
                switch entry {
                case .toolCalls(let calls):
                    inspect(calls)
                case .toolOutput(let output):
                    inspect(output)
                default:
                    break
                }
            }
            """
        case .instruments:
            """
            // Product > Profile in Xcode, then record with the
            // Foundation Models Instrument. Inspect the trace for live
            // model requests, tool activity, tokens, and timing.
            """
        }
    }
}

#Preview {
    NavigationStack {
        AgentFlowInspectorView()
    }
}
