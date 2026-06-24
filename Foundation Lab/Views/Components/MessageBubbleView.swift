//
//  MessageBubbleView.swift
//  Foundation Lab
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatesTyping = false

    var body: some View {
        VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: Spacing.small) {
            senderLabel

            if !message.isFromUser && plainText.isEmpty {
                typingIndicator
            } else {
                messageText
            }

            if message.isContextSummary {
                contextSummaryLabel
            }
        }
        .frame(maxWidth: message.isFromUser ? 620 : FoundationLabLayout.transcriptContentWidth)
        .frame(maxWidth: .infinity, alignment: message.isFromUser ? .trailing : .leading)
        .padding(.horizontal, Spacing.large)
        .contextMenu {
            if !plainText.isEmpty {
                Button("Copy Message", systemImage: "doc.on.doc", action: copyMessage)
                ShareLink(item: plainText) {
                    Label("Share Message", systemImage: "square.and.arrow.up")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message.isFromUser ? "You" : "Foundation Models response")
        .accessibilityValue(accessibilityValue)
        .accessibilityAction(named: "Copy Message", copyMessage)
    }
}

private extension MessageBubbleView {
    var senderLabel: some View {
        Label(
            message.isFromUser ? "You" : "Foundation Models",
            systemImage: message.isFromUser ? "person.crop.circle" : "apple.intelligence"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    var messageText: some View {
        Text(message.content)
            .padding(.horizontal, message.isFromUser ? Spacing.large : 0)
            .padding(.vertical, message.isFromUser ? Spacing.medium : 0)
            .textSelection(.enabled)
            .foregroundStyle(.primary)
            .background(
                message.isFromUser ? Color.secondaryBackgroundColor : .clear,
                in: .rect(cornerRadius: CornerRadius.large)
            )
            .fixedSize(horizontal: false, vertical: true)
    }

    var typingIndicator: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(animatesTyping ? 1.15 : 0.85)
                    .animation(
                        reduceMotion ? nil : .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animatesTyping
                    )
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Color.secondaryBackgroundColor, in: .capsule)
        .onAppear(perform: startTypingAnimation)
        .accessibilityLabel("Generating response")
        .accessibilityAddTraits(.updatesFrequently)
    }

    var contextSummaryLabel: some View {
        Label("Context summarized", systemImage: "arrow.triangle.2.circlepath")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHint("Earlier conversation content was condensed to preserve context space")
    }

    var plainText: String {
        String(message.content.characters)
    }

    var accessibilityValue: String {
        if plainText.isEmpty {
            String(localized: "Generating response")
        } else if message.isContextSummary {
            String(localized: "Context summary: \(plainText)")
        } else {
            plainText
        }
    }

    func startTypingAnimation() {
        animatesTyping = !reduceMotion
    }

    func copyMessage() {
        guard !plainText.isEmpty else { return }
#if os(iOS)
        UIPasteboard.general.string = plainText
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(plainText, forType: .string)
#endif
    }
}

#Preview("Conversation") {
    ScrollView {
        VStack(spacing: Spacing.xLarge) {
            MessageBubbleView(
                message: ChatMessage(
                    content: "How do I stream a response?",
                    isFromUser: true
                )
            )

            MessageBubbleView(
                message: ChatMessage(
                    content: "Create a session, then iterate over `streamResponse(to:)` updates.",
                    isFromUser: false
                )
            )

            MessageBubbleView(message: ChatMessage(content: "", isFromUser: false))
        }
        .padding(.vertical)
    }
}
