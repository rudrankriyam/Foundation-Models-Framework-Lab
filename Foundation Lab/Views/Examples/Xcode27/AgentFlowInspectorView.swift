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
                    String(
                        localized: """
                        Foundation Models does not expose a generic agent dashboard. An agentic turn is built from profiles, sessions, \
                        tools, transcript entries, and app-owned policy. Inspect live timing and token behavior with Instruments.
                        """
                    )
                )
                    .font(.body)
                    .foregroundStyle(.secondary)

                Xcode27Section(String(localized: "Framework map")) {
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

                Xcode27Section(String(localized: "Ownership boundary")) {
                    Xcode27KeyValueList(items: [
                        (String(localized: "Framework"), String(localized: "Profiles, generation, transcript")),
                        (String(localized: "Your app"), String(localized: "Routing, permissions, confirmation")),
                        (String(localized: "Evaluator"), String(localized: "Quality and regression checks")),
                        (String(localized: "Instruments"), String(localized: "Tokens, latency, control flow"))
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
        case .profile: String(localized: "Dynamic profile")
        case .generation: String(localized: "Session request")
        case .tools: String(localized: "Tool lifecycle")
        case .transcript: String(localized: "Transcript")
        case .instruments: String(localized: "Runtime trace")
        }
    }

    var summary: String {
        switch self {
        case .profile: String(localized: "Select instructions, tools, model, and options")
        case .generation: String(localized: "Generate through LanguageModelSession")
        case .tools: String(localized: "Observe calls and outputs around app code")
        case .transcript: String(localized: "Read the linear history of the session")
        case .instruments: String(localized: "Measure live latency, tokens, and control flow")
        }
    }

    var detail: String {
        switch self {
        case .profile:
            String(localized: """
            LanguageModelSession.Profile binds dynamic instructions to session configuration. DynamicProfile can change that \
            configuration from app state before requests.
            """)
        case .generation:
            String(localized: """
            LanguageModelSession owns the interaction with a LanguageModel. Respond and streamResponse are the generation boundary; \
            GenerationOptions and ContextOptions configure a request.
            """)
        case .tools:
            String(localized: """
            A Tool exposes app code to the model. Tool-calling mode controls whether tools are allowed, required, or disallowed. \
            Profile lifecycle callbacks observe calls and outputs; your app still owns authorization and side-effect policy.
            """)
        case .transcript:
            String(localized: """
            The transcript is the inspectable session history. It contains instructions, prompts, responses, tool calls, and tool \
            outputs. It does not promise fabricated cache or latency fields.
            """)
        case .instruments:
            String(localized: """
            Use the Foundation Models Instrument to inspect live prompts, response timing, token consumption, tool activity, and control \
            flow. Those measurements come from a recorded trace, not a SwiftUI sample screen.
            """)
        }
    }

    var facts: [(String, String)] {
        switch self {
        case .profile:
            [
                (String(localized: "API"), "DynamicProfile"),
                (String(localized: "Concrete type"), "Profile"),
                (String(localized: "Content"), "DynamicInstructions"),
                (String(localized: "Re-evaluates"), String(localized: "From app state"))
            ]
        case .generation:
            [
                (String(localized: "API"), "LanguageModelSession"),
                (String(localized: "Model"), String(localized: "Any LanguageModel")),
                (String(localized: "One shot"), "respond"),
                (String(localized: "Streaming"), "streamResponse")
            ]
        case .tools:
            [
                (String(localized: "API"), "Tool"),
                (String(localized: "Modes"), String(localized: "Allowed, required, disallowed")),
                (String(localized: "Before call"), "onToolCall"),
                (String(localized: "After output"), "onToolOutput")
            ]
        case .transcript:
            [
                (String(localized: "API"), "Transcript"),
                (String(localized: "Order"), String(localized: "Linear entries")),
                (String(localized: "Includes"), String(localized: "Calls and outputs")),
                (String(localized: "Use"), String(localized: "History and diagnostics"))
            ]
        case .instruments:
            [
                (String(localized: "Tool"), "Foundation Models Instrument"),
                (String(localized: "Source"), String(localized: "Recorded runtime trace")),
                (String(localized: "Shows"), String(localized: "Timing and token use")),
                (String(localized: "Use"), String(localized: "Debug and optimize"))
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
            import FoundationLabCore
            import FoundationModels

            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func makeSession() -> LanguageModelSession {
                let profile = LanguageModelSession.Profile {
                    Instructions("Help with the current task.")
                    Search1WebSearchTool()
                }
                .model(SystemLanguageModel.default)
                .toolCallingMode(.allowed)

                return LanguageModelSession(profile: profile)
            }
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
            import FoundationLabCore
            import FoundationModels

            @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
            func makeProfile() -> some LanguageModelSession.DynamicProfile {
                LanguageModelSession.Profile {
                    Search1WebSearchTool()
                }
                .toolCallingMode(.allowed)
                .onToolCall { call in
                    // Log or apply app-owned authorization policy.
                }
                .onToolOutput { call, output in
                    // Record the observed output.
                }
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
