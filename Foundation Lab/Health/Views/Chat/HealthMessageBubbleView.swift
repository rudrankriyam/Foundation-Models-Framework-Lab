//
//  HealthMessageBubbleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct HealthMessageBubbleView: View {
    let content: String
    let isFromUser: Bool

    var body: some View {
        VStack(alignment: isFromUser ? .trailing : .leading, spacing: Spacing.small) {
            Label(
                isFromUser ? "You" : "Foundation Models",
                systemImage: isFromUser ? "person.crop.circle" : "apple.intelligence"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(content)
                .font(.body)
                .textSelection(.enabled)
                .padding(.horizontal, isFromUser ? Spacing.large : 0)
                .padding(.vertical, isFromUser ? Spacing.medium : 0)
                .background(
                    isFromUser ? Color.secondaryBackgroundColor : .clear,
                    in: .rect(cornerRadius: CornerRadius.large)
                )
        }
        .frame(maxWidth: isFromUser ? 620 : FoundationLabLayout.transcriptContentWidth)
        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
        .padding(.horizontal, Spacing.large)
        .contextMenu {
            Button("Copy Message", systemImage: "doc.on.doc", action: copyMessage)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isFromUser ? String(localized: "You") : String(localized: "Foundation Models response")
        )
        .accessibilityValue(content)
        .accessibilityAction(named: "Copy Message", copyMessage)
    }

    private func copyMessage() {
        #if os(iOS)
        UIPasteboard.general.string = content
        UIAccessibility.post(
            notification: .announcement,
            argument: String(localized: "Message copied to the clipboard")
        )
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #endif
    }
}

#Preview {
    VStack(spacing: 16) {
        HealthMessageBubbleView(
            content: "Ask about HealthKit data available on this device.",
            isFromUser: false
        )

        HealthMessageBubbleView(
            content: "Which Health measurements are available today?",
            isFromUser: true
        )

        HealthMessageBubbleView(
            content: """
            HealthKit returned 8,432 steps for today and 7.2 hours of sleep for last night.
            No heart-rate measurement was available.
            """,
            isFromUser: false
        )
    }
    .padding()
}
