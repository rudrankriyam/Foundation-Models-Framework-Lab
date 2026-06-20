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
        HStack(alignment: .bottom, spacing: 8) {
            if !isFromUser {
                // Health AI avatar
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 28, height: 28)

                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityHidden(true)
            }

            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                // Message content
                Text(content)
                    .font(.body)
                    .foregroundStyle(isFromUser ? .primary : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(isFromUser ? Color.primary.opacity(0.08) : Color.primary.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isFromUser ? Color.primary.opacity(0.1) : Color.clear, lineWidth: 1)
                    )
                    .frame(maxWidth: 280, alignment: isFromUser ? .trailing : .leading)
            }

            if isFromUser {
                // User avatar
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    )
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isFromUser ? String(localized: "You said") : String(localized: "Health AI replied")
        )
        .accessibilityValue(content)
        .accessibilityActions {
            Button("Copy message") {
                #if os(iOS)
                UIPasteboard.general.string = content
                UIAccessibility.post(
                    notification: .announcement,
                    argument: String(localized: "Message copied to clipboard")
                )
                #elseif os(macOS)
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(content, forType: .string)
                #endif
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HealthMessageBubbleView(
            content: "Ask me about health data available on this device.",
            isFromUser: false
        )

        HealthMessageBubbleView(
            content: "Can you show me my health stats for today?",
            isFromUser: true
        )

        HealthMessageBubbleView(
            content: """
            Of course! Let me fetch your health data for today. You've been doing great with 8,432 steps so far!
            That's 84% of your daily goal. Your sleep last night was also good at 7.2 hours. Keep up the
            excellent work!
            """,
            isFromUser: false
        )
    }
    .padding()
    .background(Color.adaptiveBackground)
}
