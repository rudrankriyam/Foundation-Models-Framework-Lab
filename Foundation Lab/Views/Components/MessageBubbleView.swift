//
//  MessageBubbleView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/9/25.
//

import SwiftUI
import FoundationModels

struct MessageBubbleView: View {
  let message: ChatMessage
  @Environment(ChatViewModel.self) var viewModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var animateTyping = false
  @AccessibilityFocusState private var isMessageFocused: Bool

  var body: some View {
    HStack {
      if message.isFromUser {
        Spacer(minLength: 60)
        messageContent
      } else {
        messageContent
        Spacer(minLength: 60)
      }
    }
    .padding(.horizontal)
    .accessibilityElement(children: .combine)
    .accessibilityLabel(accessibilityMessageLabel)
    .accessibilityValue(accessibilityMessageValue)
    .accessibilityHint(accessibilityMessageHint)
    .accessibilityAddTraits(accessibilityTraits)
    .accessibilityActions {
      if !message.content.characters.isEmpty {
        Button("Copy message") {
          copyMessageToClipboard()
        }

        Button("Share message") {
          shareMessage()
        }
      }
    }
    .accessibilityFocused($isMessageFocused)
    .task {
      guard !message.isFromUser, !message.content.characters.isEmpty else { return }
      try? await Task.sleep(for: .milliseconds(500))
      guard !Task.isCancelled else { return }
      isMessageFocused = true
    }
  }

  private var messageContent: some View {
    #if os(iOS) || os(macOS)
    GlassEffectContainer(spacing: Spacing.small) {
      messageContentStack
    }
    #else
    messageContentStack
    #endif
  }

  private var messageContentStack: some View {
    VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: Spacing.xSmall) {
      if !message.isFromUser && message.content.characters.isEmpty {
        typingIndicator
      } else {
        messageText
      }

      if message.isContextSummary {
        contextSummaryIndicator
      }
    }
  }

  private var typingIndicator: some View {
    HStack(spacing: Spacing.xSmall) {
      ForEach(0..<3, id: \.self) { index in
        Circle()
          .fill(.secondary)
          .frame(width: 6, height: 6)
          .scaleEffect(animateTyping ? 1.2 : 0.8)
          .animation(
            reduceMotion ? nil : .easeInOut(duration: 0.6)
              .repeatForever()
              .delay(Double(index) * 0.2),
            value: animateTyping
          )
      }
    }
    .padding(.horizontal, Spacing.medium)
    .padding(.vertical, Spacing.small)
    .onAppear {
      animateTyping = !reduceMotion
    }
    .accessibilityLabel("Assistant is typing")
    .accessibilityAddTraits(.updatesFrequently)
    #if os(iOS) || os(macOS)
    .glassEffect(
      .regular.tint(.gray.opacity(0.3)),
      in: .rect(cornerRadius: CornerRadius.large + 2)
    )
    #endif
  }

  private var messageText: some View {
    Text(message.content)
      .padding(.horizontal, Spacing.large)
      .padding(.vertical, Spacing.small + 2)
      .textSelection(.enabled)
      .accessibilityRespondsToUserInteraction(true)
      .foregroundStyle(
        message.isFromUser ? .white : Color.primary
      )
      #if os(iOS) || os(macOS)
      .glassEffect(
        message.isFromUser
          ? .regular.tint(.main).interactive()
          : .regular.tint(.gray.opacity(0.3)),
        in: .rect(cornerRadius: CornerRadius.large + 2)
      )
      #endif
  }

  private var contextSummaryIndicator: some View {
    HStack {
      Image(systemName: "arrow.triangle.2.circlepath")
        .foregroundStyle(.orange)
        .accessibilityHidden(true)  // Decorative icon
      Text("Context summarized")
        .font(.caption2)
        .foregroundStyle(.orange)
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Context summary indicator")
    .accessibilityValue("This message contains a summary of previous conversation context")
  }

  // MARK: - Accessibility Computed Properties

  private var accessibilityMessageLabel: String {
    let sender = message.isFromUser ? "You said" : "Assistant replied"
    let timestamp = formatTimestampForAccessibility(message.timestamp)

    if message.content.characters.isEmpty {
      return "\(sender), typing indicator, \(timestamp)"
    }

    let contextPrefix = message.isContextSummary ? "Context summary: " : ""
    return "\(sender), \(contextPrefix)\(timestamp)"
  }

  private var accessibilityMessageValue: String {
    if message.content.characters.isEmpty {
      return "Assistant is currently typing a response"
    }
    return String(message.content.characters)
  }

  private var accessibilityMessageHint: String {
    if message.content.characters.isEmpty {
      return "Please wait for the assistant to finish typing"
    }

    if message.isContextSummary {
      return
        "This is a summary of previous conversation context. Double-tap to interact with message options."
    }

    return "Double-tap to access message options like copy and share"
  }

  private var accessibilityTraits: AccessibilityTraits {
    var traits: AccessibilityTraits = []

    if message.content.characters.isEmpty {
      _ = traits.insert(.updatesFrequently)
    }

    if message.isContextSummary {
      _ = traits.insert(.isHeader)
    }

    return traits
  }

  // MARK: - Accessibility Helper Methods

  private func formatTimestampForAccessibility(_ timestamp: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: timestamp, relativeTo: Date())
  }

  private func copyMessageToClipboard() {
    #if os(iOS)
      UIPasteboard.general.string = String(message.content.characters)
      // Provide haptic feedback
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()

      // Announce to VoiceOver
      UIAccessibility.post(notification: .announcement, argument: "Message copied to clipboard")
    #elseif os(macOS)
      NSPasteboard.general.setString(String(message.content.characters), forType: .string)
    #endif
  }

  private func shareMessage() {
    #if os(iOS)
      let activityVC = UIActivityViewController(
        activityItems: [String(message.content.characters)],
        applicationActivities: nil
      )

      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
        let window = windowScene.windows.first,
        let rootVC = window.rootViewController {

        // For iPad - set popover presentation
        if let popover = activityVC.popoverPresentationController {
          popover.sourceView = window
          popover.sourceRect = CGRect(
            x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
          popover.permittedArrowDirections = []
        }

        rootVC.present(activityVC, animated: true)

        // Announce to VoiceOver
        UIAccessibility.post(notification: .announcement, argument: "Share sheet opened")
      }
    #endif
  }
}

// MARK: - Essential Previews

#Preview("Message Bubbles") {
  ScrollView {
    VStack(spacing: Spacing.large) {
      Text("Chat Message Examples")
        .font(.headline)
        .padding()

      MessageBubbleView(message: ChatMessage(
        content: "Hello! How are you today?",
        isFromUser: true
      ))

      MessageBubbleView(message: ChatMessage(
        content: "I'm doing great! How can I help you?",
        isFromUser: false
      ))

      MessageBubbleView(message: ChatMessage(
        content: "## Foundation Models\n\nThey provide **powerful** on-device AI capabilities. For *streaming*, " +
                "you can use `async sequences` to receive partial responses as they're generated, creating a more " +
                "**responsive** user experience.",
        isFromUser: false
      ))

      MessageBubbleView(message: ChatMessage(
        content: "",
        isFromUser: false
      ))
    }
    .padding()
  }
  .environment(ChatViewModel())
}

#Preview("Conversation Flow") {
  ScrollView {
    VStack(spacing: Spacing.medium) {
      MessageBubbleView(
        message: ChatMessage(
          content: "Hi! I need help with Foundation Models.",
          isFromUser: true
        ))

      MessageBubbleView(
        message: ChatMessage(
          content:
            "I'd be happy to help you with Foundation Models! What specific area would you like to focus on?",
          isFromUser: false
        ))

      MessageBubbleView(
        message: ChatMessage(
          content: "How do I implement streaming responses?",
          isFromUser: true
        ))

      MessageBubbleView(
        message: ChatMessage(
          content:
            "For streaming responses, you can use async sequences with LanguageModelSession. This allows you to " +
            "receive partial responses as they're generated, creating a more responsive user experience.",
          isFromUser: false
        ))

      MessageBubbleView(message: ChatMessage(content: "", isFromUser: false))
    }
    .padding()
  }
  .environment(ChatViewModel())
}

#Preview("Dark Mode") {
  ScrollView {
    VStack(spacing: Spacing.medium) {
      MessageBubbleView(message: ChatMessage(
        content: "Hello! How are you today?",
        isFromUser: true
      ))

      MessageBubbleView(message: ChatMessage(
        content: "## Rich Text Support\n\nI can display **bold**, *italic*, and `code` formatting!",
        isFromUser: false
      ))
    }
    .padding()
  }
  .preferredColorScheme(.dark)
  .environment(ChatViewModel())
}
