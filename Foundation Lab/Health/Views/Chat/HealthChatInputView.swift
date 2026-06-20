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

    private var backgroundColor: Color {
        #if os(macOS)
        Color(NSColor.windowBackgroundColor)
        #else
        Color(UIColor.systemBackground)
        #endif
    }

    var body: some View {
        VStack(spacing: 12) {
            // Quick action suggestions
            if messageText.isEmpty && !chatViewModel.isLoading {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        QuickActionChip(text: String(localized: "How am I doing today?")) {
                            messageText = String(localized: "How am I doing today?")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Set a fitness goal")) {
                            messageText = String(localized: "Help me set a fitness goal")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Sleep tips")) {
                            messageText = String(localized: "Give me tips to improve my sleep")
                            sendMessage()
                        }

                        QuickActionChip(text: String(localized: "Weekly summary")) {
                            messageText = String(localized: "Show me my weekly health summary")
                            sendMessage()
                        }
                    }
                    .padding(.horizontal)
                }
                .scrollIndicators(.hidden)
                .padding(.vertical, 8)
            }

            // Input field
            HStack(spacing: 12) {
                TextField("Ask Health AI anything...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .focused($isTextFieldFocused)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.quaternary, in: .rect(cornerRadius: 24))
                    .onSubmit {
                        sendMessage()
                    }
                    #if os(iOS)
                    .submitLabel(.send)
                    #endif

                Button(action: sendMessage) {
                    ZStack {
                        Circle()
                            .fill(messageText.isEmpty ? Color.primary.opacity(0.06) : Color.primary.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: "arrow.up")
                            .font(.callout.weight(.medium))
                            .foregroundStyle(messageText.isEmpty ? .tertiary : .primary)
                    }
                }
                .accessibilityLabel("Send message")
                .disabled(
                    messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    chatViewModel.isLoading ||
                    chatViewModel.isSummarizing
                )
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(
            backgroundColor
                .ignoresSafeArea()
        )
    }

    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        messageText = ""
        isTextFieldFocused = true // Keep focus for continuous conversation

        chatViewModel.sendMessage(trimmedMessage)
    }
}

struct QuickActionChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .accessibilityHint("Sends this suggested message")
    }
}
