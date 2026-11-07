//
//  SessionStateLabLiveView.swift
//  FoundationLab
//

import SwiftUI

#if canImport(FoundationModels, _version: 2.2)
@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct SessionStateLabLiveView: View {
    @State private var model = SessionStateLabViewModel()
    @State private var isComparisonExpanded = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                Text(
                    """
                    A parent profile owns a reply budget with @SessionState and passes $remainingReplies to a child profile and \
                    its dynamic instructions. Each response spends one reply until the parent switches to a budget-spent profile.
                    """
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if let issue = model.readinessIssue {
                    DynamicProfileWorkflowIssueView(
                        title: String(localized: "System model unavailable"),
                        message: issue,
                        systemImage: "exclamationmark.circle.fill",
                        tint: .orange
                    )
                }

                stateSection
                promptSection

                if let errorMessage = model.errorMessage {
                    DynamicProfileWorkflowIssueView(
                        title: nil,
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle.fill",
                        tint: .red
                    )
                }

                if !model.turns.isEmpty {
                    resultsSection
                }

                comparison
                CodeDisclosure(code: model.codeExample)
            }
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .navigationTitle("Session State")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Share state across one session's profiles")
        #endif
        .onDisappear(perform: model.cancelRun)
    }

    private var stateSection: some View {
        Xcode27Section(String(localized: "Reply Budget")) {
            Xcode27KeyValueList(items: [
                (String(localized: "Initial value"), model.replyBudget.formatted()),
                (
                    String(localized: "Remaining, reported by the profile"),
                    model.latestReportedRemaining?.formatted() ?? String(localized: "Not reported yet")
                ),
                (String(localized: "Turns in this session"), model.turns.count.formatted())
            ])
        }
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Enter a prompt", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isExecuting)
                    .accessibilityHint("The prompt is sent to the same session, which keeps its reply budget")

                HStack(spacing: Spacing.small) {
                    Button("New Session", systemImage: "arrow.counterclockwise", action: model.startNewSession)
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
                        .disabled(model.isExecuting)

                    Button(
                        model.isStopping ? "Stopping…" : (model.isRunning ? "Stop" : "Send"),
                        systemImage: model.isStopping ? "hourglass" : (model.isRunning ? "stop.fill" : "paperplane.fill"),
                        action: toggleRun
                    )
                    .buttonStyle(.glassProminent)
                    .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
                    .disabled(model.isStopping || (!model.isRunning && !model.canRun))
                }
                .controlSize(.large)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var resultsSection: some View {
        Xcode27Section(String(localized: "Observed Results")) {
            LazyVStack(alignment: .leading, spacing: Spacing.large) {
                ForEach(model.turns.reversed()) { turn in
                    SessionStateLabTurnView(turn: turn)

                    if turn.id != model.turns.first?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var comparison: some View {
        DisclosureGroup("SessionState and SessionProperty", isExpanded: $isComparisonExpanded) {
            Text(
                """
                @SessionState is declared inside a profile or dynamic instructions, which owns its value for the session's \
                lifetime. Children receive it only through a SessionBinding passed to their initializer. @SessionProperty reads a \
                key on SessionPropertyValues, which the app can also read and write through session.properties. This lab shows \
                the remaining budget only because the child profile reports it from onPrompt and onResponse. A new session \
                starts from the initial value.
                """
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, Spacing.small)
        }
        .font(.callout)
    }

    private func toggleRun() {
        if model.isRunning {
            model.cancelRun()
        } else {
            model.startRun()
        }
    }
}
#endif
