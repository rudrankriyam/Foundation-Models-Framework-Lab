//
//  ToolTrajectoryPathView.swift
//  FoundationLab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct ToolTrajectoryPathView: View {
    private struct Item: Identifiable {
        let id: String
        let title: String
        let detail: String
        let systemImage: String
        let tint: Color
    }

    private let items: [Item]

    init(expectedCalls: [FoundationLabToolTrajectoryEvaluation.Call]) {
        self.items = expectedCalls.enumerated().map { index, call in
            Item(
                id: "expected-\(index)-\(call.id)",
                title: call.name,
                detail: call.arguments,
                systemImage: "hammer",
                tint: .blue
            )
        }
    }

    init(observedEvents: [SessionTranscriptSnapshot.ToolEvent]) {
        self.items = observedEvents.map { event in
            switch event.kind {
            case .call:
                Item(
                    id: event.id,
                    title: String(localized: "Call · \(event.toolName)"),
                    detail: event.detail,
                    systemImage: "hammer.fill",
                    tint: .blue
                )
            case .output:
                Item(
                    id: event.id,
                    title: String(localized: "Output · \(event.toolName)"),
                    detail: event.detail,
                    systemImage: "arrow.turn.down.right",
                    tint: .secondary
                )
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.enumerated(), id: \.element.id) { index, item in
                HStack(alignment: .top, spacing: Spacing.medium) {
                    Image(systemName: item.systemImage)
                        .foregroundStyle(item.tint)
                        .frame(width: 24, height: 24)

                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(item.title)
                            .font(.subheadline)
                            .bold()
                        Text(item.detail)
                            .font(.footnote.monospaced())
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }

                    Spacer(minLength: Spacing.small)
                }
                .frame(
                    maxWidth: .infinity,
                    minHeight: FoundationLabLayout.minimumTouchTarget,
                    alignment: .leading
                )
                .padding(.vertical, Spacing.small)
                .accessibilityElement(children: .combine)

                if index < items.count - 1 {
                    Divider()
                        .padding(.leading, Spacing.xxLarge)
                }
            }
        }
    }
}
