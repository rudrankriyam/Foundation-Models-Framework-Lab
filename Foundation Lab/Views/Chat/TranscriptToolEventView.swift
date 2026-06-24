//
//  TranscriptToolEventView.swift
//  Foundation Lab
//

import SwiftUI

struct TranscriptToolEventView: View {
    enum Kind {
        case call
        case result

        var title: LocalizedStringKey {
            switch self {
            case .call:
                "Tool Call"
            case .result:
                "Tool Result"
            }
        }

        var systemImage: String {
            switch self {
            case .call:
                "wrench.and.screwdriver"
            case .result:
                "checkmark.bubble"
            }
        }
    }

    let kind: Kind
    let toolName: String
    let detail: String

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            if detail.isEmpty {
                Text("No details were recorded.")
                    .foregroundStyle(.secondary)
            } else {
                Text(detail)
                    .font(.callout.monospaced())
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(kind.title)
                    Text(toolName)
                        .font(.subheadline.monospaced())
                        .foregroundStyle(.secondary)
                }
            } icon: {
                Image(systemName: kind.systemImage)
                    .foregroundStyle(.tint)
            }
            .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.xSmall)
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.medium))
        .frame(maxWidth: FoundationLabLayout.transcriptContentWidth)
        .padding(.horizontal, Spacing.large)
        .accessibilityHint("Expands to show the recorded tool details")
    }
}
