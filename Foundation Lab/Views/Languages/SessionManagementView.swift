//
//  SessionManagementView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI
import FoundationLabCore

struct SessionManagementView: View {
    @State private var conversationResults: [LanguageSessionExchange] = []
    @State private var isRunning = false
    @State private var errorMessage: String?
    private let runLanguageSessionDemoUseCase = RunLanguageSessionDemoUseCase()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("Use one session to switch languages while preserving the conversation’s context.")
                    .foregroundStyle(.secondary)

                ToolExecuteButton(
                    "Run Conversation",
                    systemImage: "bubble.left.and.bubble.right",
                    isRunning: isRunning
                ) {
                    Task { await startMultilingualConversation() }
                }

                if let errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                if !conversationResults.isEmpty {
                    conversationSection
                }

                CodeDisclosure(code: codeExample)
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Language Sessions")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
    }

    private var codeExample: String {
        """
import FoundationLabCore

let result = try await RunConversationUseCase().execute(
    RunConversationRequest(
        prompts: [
            "Hello, how are you?",
            "Hola, ¿cómo estás?",
            "Now answer in English please",
            "What language did I first speak to you in?"
        ],
        systemPrompt: "You are a multilingual assistant who can naturally switch between languages and maintain conversational context.",
        context: CapabilityInvocationContext(source: .app)
    )
)
"""
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Conversation")
                .font(.headline)

            LazyVStack(spacing: Spacing.small) {
                ForEach(conversationResults.indices, id: \.self) { index in
                    ConversationStepCard(
                        step: conversationResults[index],
                        stepNumber: index + 1
                    )
                }
            }
        }
    }

    @MainActor
    private func startMultilingualConversation() async {
        isRunning = true
        errorMessage = nil
        conversationResults = []

        do {
            let steps = FoundationLabLanguageCatalog.defaultConversationSteps.map {
                LanguageConversationStep(label: $0.label, prompt: $0.prompt)
            }
            let result = try await runLanguageSessionDemoUseCase.execute(
                RunLanguageSessionDemoRequest(
                    steps: steps,
                    systemPrompt: FoundationLabLanguageCatalog.multilingualSystemPrompt,
                    context: CapabilityInvocationContext(
                        source: .app,
                        localeIdentifier: Locale.current.identifier
                    )
                )
            )
            conversationResults = result.exchanges
        } catch {
            errorMessage = error.localizedDescription
        }

        isRunning = false
    }
}

private struct ConversationStepCard: View {
    let step: LanguageSessionExchange
    let stepNumber: Int

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Prompt")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step.prompt)
                        .font(.body)
                }

                Divider()

                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Model Response")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(step.response)
                        .font(.body)
                        .foregroundStyle(step.isError ? Color.red : Color.primary)
                        .textSelection(.enabled)
                }
            }
            .padding(.top, Spacing.small)
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: "\(min(stepNumber, 50)).circle.fill")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)

                Text(step.label)
                    .font(.headline)

                if step.isError {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.red)
                        .accessibilityLabel("Error")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SessionManagementView()
    }
}
