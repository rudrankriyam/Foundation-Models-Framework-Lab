//
//  RiskyToolConfirmationDemoView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import SwiftUI

struct RiskyToolConfirmationDemoView: View {
    @State private var currentPrompt = "Send the invoice reminder to the client."
    @State private var decision = ToolConfirmationDecision.pending

    var body: some View {
        ExampleViewBase(
            title: "Tool Safety",
            description: "Pause risky tool calls before side effects",
            defaultPrompt: "Send the invoice reminder to the client.",
            currentPrompt: $currentPrompt,
            codeExample: codeExample,
            onRun: cycleDecision,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27StatusRow(
                    title: "Current Decision",
                    value: decision.title,
                    systemImage: decision.icon,
                    tint: decision.tint
                )

                Xcode27Section("Tool Call") {
                    VStack(alignment: .leading, spacing: Spacing.medium) {
                        Xcode27KeyValueList(items: [
                            ("Tool", "sendMessage"),
                            ("Recipient", "Client"),
                            ("Side effect", "External message"),
                            ("Risk", "User-visible")
                        ])

                        Text(decision.explanation)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }

                Xcode27Section("Recommended Boundary") {
                    VStack(alignment: .leading, spacing: 0) {
                        Xcode27InfoRow(
                            title: "Low risk",
                            detail: "Read-only tools can run with logging.",
                            systemImage: "eye",
                            tint: .green
                        )
                            .padding(.vertical, Spacing.small)
                        Divider()
                        Xcode27InfoRow(
                            title: "Medium risk",
                            detail: "Draft-changing tools should show undo or review.",
                            systemImage: "pencil",
                            tint: .orange
                        )
                            .padding(.vertical, Spacing.small)
                        Divider()
                        Xcode27InfoRow(
                            title: "High risk",
                            detail: "External, destructive, or financial tools should require confirmation.",
                            systemImage: "exclamationmark.triangle",
                            tint: .red
                        )
                            .padding(.vertical, Spacing.small)
                    }
                }
            }
        }
    }

    private func cycleDecision() {
        switch decision {
        case .pending: decision = .approved
        case .approved: decision = .denied
        case .denied: decision = .pending
        }
    }

    private func reset() {
        currentPrompt = ""
        decision = .pending
    }

    private var codeExample: String {
        """
        Profile {
            Instructions("Help the user manage client follow-up.")
            SendMessageTool()
        }
        .onToolCall { call in
            guard call.toolName == "sendMessage" else { return }
            guard await confirmWithUser(call) else {
                throw ToolSafetyError.userDeniedConfirmation
            }
        }
        """
    }
}

private enum ToolConfirmationDecision {
    case pending
    case approved
    case denied

    var title: String {
        switch self {
        case .pending: return "Needs confirmation"
        case .approved: return "Approved by user"
        case .denied: return "Denied and recovered"
        }
    }

    var explanation: String {
        switch self {
        case .pending: return "The model prepared arguments, but the app has not sent anything yet."
        case .approved: return "The user confirmed the action, so the tool can perform the side effect."
        case .denied: return "The tool throws a controlled error and the model continues with a safer alternative."
        }
    }

    var icon: String {
        switch self {
        case .pending: return "questionmark.circle"
        case .approved: return "checkmark.circle.fill"
        case .denied: return "xmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .denied: return .red
        }
    }
}

#Preview {
    NavigationStack {
        RiskyToolConfirmationDemoView()
    }
}
