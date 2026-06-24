//
//  HealthChatInputView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/23/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct HealthChatInputView: View {
    @Binding var messageText: String
    let chatViewModel: HealthChatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: Spacing.small) {
            Divider()

            if messageText.isEmpty && !chatViewModel.isLoading {
                ScrollView(.horizontal) {
                    HStack(spacing: Spacing.small) {
                        QuickActionChip(text: String(localized: "Available today")) {
                            messageText = String(localized: "Show the Health data available for today.")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Steps")) {
                            messageText = String(localized: "What step data is available for today?")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Sleep")) {
                            messageText = String(localized: "What sleep data is available?")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Recorded this week")) {
                            messageText = String(localized: "Summarize the Health data recorded this week.")
                            sendMessage()
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
            }

            HStack(alignment: .bottom, spacing: Spacing.small) {
                TextField("Ask about Health data", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, Spacing.medium)
                    .padding(.vertical, Spacing.small)
                    .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
                    .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.medium))
                    .onSubmit {
                        sendMessage()
                    }
                    #if os(iOS)
                    .submitLabel(.send)
                    #endif

                Button("Send Message", systemImage: "arrow.up", action: sendMessage)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(
                    minWidth: FoundationLabLayout.minimumTouchTarget,
                    minHeight: FoundationLabLayout.minimumTouchTarget
                )
                .accessibilityLabel("Send message")
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    chatViewModel.isLoading ||
                    chatViewModel.isSummarizing
                )
            }
            .padding(.horizontal, Spacing.large)
            .padding(.bottom, Spacing.medium)
        }
        .background(.bar)
    }

    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty,
              !chatViewModel.isLoading,
              !chatViewModel.isSummarizing else { return }

        messageText = ""
        isTextFieldFocused = true

        chatViewModel.sendMessage(trimmedMessage)
    }
}

private struct QuickActionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.callout)
        }
        .buttonStyle(.bordered)
        .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
        .accessibilityHint("Sends this suggested message")
    }
}
