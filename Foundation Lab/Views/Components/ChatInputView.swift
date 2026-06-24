//
//  ChatInputView.swift
//  Foundation Lab
//

import SwiftUI

struct ChatInputView: View {
    @Binding var messageText: String
    var chatViewModel: ChatViewModel
    @FocusState.Binding var isTextFieldFocused: Bool
    var onSend: (@MainActor (String) async -> Void)?
    var onVoiceWillSend: (@MainActor () -> Void)?
    var onVoiceCompleted: (@MainActor (String, String, Date, TimeInterval) -> Void)?

    init(
        messageText: Binding<String>,
        chatViewModel: ChatViewModel,
        isTextFieldFocused: FocusState<Bool>.Binding,
        onSend: (@MainActor (String) async -> Void)? = nil,
        onVoiceWillSend: (@MainActor () -> Void)? = nil,
        onVoiceCompleted: (@MainActor (String, String, Date, TimeInterval) -> Void)? = nil
    ) {
        _messageText = messageText
        self.chatViewModel = chatViewModel
        _isTextFieldFocused = isTextFieldFocused
        self.onSend = onSend
        self.onVoiceWillSend = onVoiceWillSend
        self.onVoiceCompleted = onVoiceCompleted
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(alignment: .bottom, spacing: Spacing.small) {
                composerField
                composerAction
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: FoundationLabLayout.transcriptContentWidth)
            .frame(maxWidth: .infinity)
        }
        .background(.bar)
    }
}

private extension ChatInputView {
    var composerField: some View {
        Group {
            if case .listening(let partialText) = chatViewModel.voiceState {
                Label {
                    Text(partialText.isEmpty ? String(localized: "Listening…") : partialText)
                        .foregroundStyle(.secondary)
                        .italic()
                } icon: {
                    Image(systemName: "waveform")
                        .foregroundStyle(.tint)
                }
            } else {
                TextField("Enter a prompt", text: $messageText, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onSubmit(sendMessage)
#if os(iOS)
                    .submitLabel(.send)
#endif
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
        .background(Color.secondaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.medium))
    }

    @ViewBuilder
    var composerAction: some View {
        if chatViewModel.voiceState == .preparing {
            ProgressView()
                .controlSize(.small)
                .frame(
                    minWidth: FoundationLabLayout.minimumTouchTarget,
                    minHeight: FoundationLabLayout.minimumTouchTarget
                )
                .accessibilityLabel("Preparing voice mode")

            composerButton(
                "Cancel Voice Mode",
                systemImage: "xmark",
                tint: .secondary,
                action: chatViewModel.cancelVoiceMode
            )
        } else if chatViewModel.isLoading {
            composerButton(
                "Stop Generating",
                systemImage: "stop.fill",
                tint: .red,
                action: chatViewModel.cancelGeneration
            )
            .keyboardShortcut(".", modifiers: .command)
        } else if case .listening = chatViewModel.voiceState {
            composerButton(
                "Finish Voice Message",
                systemImage: "stop.fill",
                tint: .red,
                action: finishVoiceMessage
            )
        } else if case .speaking = chatViewModel.voiceState {
            composerButton(
                "Stop Speaking",
                systemImage: "speaker.slash.fill",
                tint: .orange,
                action: chatViewModel.stopSpeaking
            )
        } else if trimmedMessage.isEmpty {
            composerButton(
                "Start Voice Mode",
                systemImage: "waveform",
                tint: .accentColor,
                action: startVoiceMode
            )
            .disabled(chatViewModel.voiceState.isActive && !chatViewModel.voiceState.isError)
        } else {
            Button("Send Message", systemImage: "arrow.up", action: sendMessage)
                .labelStyle(.iconOnly)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(
                    minWidth: FoundationLabLayout.minimumTouchTarget,
                    minHeight: FoundationLabLayout.minimumTouchTarget
                )
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!chatViewModel.canStartTextGeneration)
        }
    }

    func composerButton(
        _ title: LocalizedStringKey,
        systemImage: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(title, systemImage: systemImage, action: action)
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .controlSize(.large)
            .tint(tint)
            .frame(
                minWidth: FoundationLabLayout.minimumTouchTarget,
                minHeight: FoundationLabLayout.minimumTouchTarget
            )
    }

    var trimmedMessage: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func sendMessage() {
        guard !trimmedMessage.isEmpty,
              chatViewModel.canStartTextGeneration else { return }

        let outgoingMessage = trimmedMessage
        messageText = ""
        isTextFieldFocused = true

        Task {
            if let onSend {
                await onSend(outgoingMessage)
            } else {
                await chatViewModel.sendMessage(outgoingMessage)
            }
        }
    }

    func startVoiceMode() {
        Task {
            await chatViewModel.startVoiceMode()
        }
    }

    func finishVoiceMessage() {
        Task {
            await endVoiceAndSend()
        }
    }

    @MainActor
    func endVoiceAndSend() async {
        onVoiceWillSend?()
        let startedAt = Date.now
        guard let result = await chatViewModel.stopVoiceModeAndSend() else { return }
        onVoiceCompleted?(
            result.prompt,
            result.response,
            startedAt,
            Date.now.timeIntervalSince(startedAt)
        )
    }
}
