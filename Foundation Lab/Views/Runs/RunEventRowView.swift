//
//  RunEventRowView.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct RunEventRowView: View {
    let event: FoundationLabExperimentEvent

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    eventLabel
                    Spacer(minLength: Spacing.medium)
                    timestamp
                }

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    eventLabel
                    timestamp
                }
            }

            if !event.text.isEmpty {
                Text(event.text)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let toolName = event.toolName {
                Label(toolName, systemImage: "wrench.and.screwdriver")
                    .font(.subheadline.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xSmall)
        .accessibilityElement(children: .combine)
    }

    private var eventLabel: some View {
        Label(event.title, systemImage: event.systemImage)
            .font(.headline)
    }

    @ViewBuilder
    private var timestamp: some View {
        if let timestamp = event.timestamp {
            Text(timestamp, format: .dateTime.hour().minute().second())
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private extension FoundationLabExperimentEvent {
    var title: String {
        switch kind {
        case .message:
            role.displayName
        case .toolCall:
            String(localized: "Tool Call")
        case .toolResult:
            String(localized: "Tool Result")
        }
    }

    var systemImage: String {
        switch kind {
        case .toolCall:
            "wrench.and.screwdriver"
        case .toolResult:
            "checkmark.bubble"
        case .message:
            role.systemImage
        }
    }
}

private extension FoundationLabExperimentEvent.Role {
    var displayName: String {
        switch self {
        case .system:
            String(localized: "System")
        case .user:
            String(localized: "Prompt")
        case .assistant:
            String(localized: "Response")
        case .tool:
            String(localized: "Tool")
        }
    }

    var systemImage: String {
        switch self {
        case .system:
            "gearshape"
        case .user:
            "person.crop.circle"
        case .assistant:
            "sparkles"
        case .tool:
            "wrench.and.screwdriver"
        }
    }
}
