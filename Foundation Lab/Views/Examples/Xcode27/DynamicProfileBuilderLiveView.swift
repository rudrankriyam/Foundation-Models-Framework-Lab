//
//  DynamicProfileBuilderLiveView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DynamicProfileBuilderLiveView: View {
    @State private var model = DynamicProfileWorkflowViewModel()
    @State private var isFixtureExpanded = false
    @State private var isBoundaryExpanded = false

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                Text(
                    """
                    Keep one session while its active profile changes with the task. Inspect the bundled release record on device, \
                    then review the recorded evidence with either the system model or Private Cloud Compute.
                    """
                )
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

                if let issue = model.readinessIssue {
                    DynamicProfileWorkflowIssueView(
                        title: model.activeRuntime.unavailableTitle,
                        message: issue,
                        systemImage: "exclamationmark.circle.fill",
                        tint: .orange
                    )
                }

                workflowSection
                localFixture
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

                ownershipBoundary
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
        .navigationTitle("Session Profile Builder")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Run one session across changing profiles")
        #endif
        .onDisappear(perform: model.cancelRun)
    }

    private var workflowSection: some View {
        Xcode27Section(String(localized: "Workflow")) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Picker(
                    "Stage",
                    selection: Binding(
                        get: { model.stage },
                        set: model.selectStage
                    )
                ) {
                    ForEach(DynamicProfileWorkflowStage.allCases) { stage in
                        Label(stage.title, systemImage: stage.systemImage)
                            .tag(stage)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(model.isExecuting)

                Text(model.stage.summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if model.stage == .review {
                    Picker(
                        "Model",
                        selection: Binding(
                            get: { model.reviewRuntime },
                            set: model.selectReviewRuntime
                        )
                    ) {
                        ForEach(DynamicProfileReviewRuntime.allCases) { runtime in
                            Text(runtime.title).tag(runtime)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(model.isExecuting)
                }

                DynamicProfileRuntimeEvidenceView(runtime: model.activeRuntime)
                Divider()
                Xcode27KeyValueList(items: [
                    (String(localized: "Transcript entries"), model.transcriptEntryCount.formatted())
                ])
            }
        }
    }

    private var localFixture: some View {
        DisclosureGroup("Read-only Local Tool", isExpanded: $isFixtureExpanded) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                LabeledContent("Tool", value: "read_local_release_record")
                LabeledContent("Sample record", value: "foundation-lab")
                Text(
                    """
                    Inspect requires the deterministic tool before the model answers. Review removes the tool and uses only the \
                    transcript that this session has already recorded.
                    """
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.small)
            .font(.callout)
        }
        .font(.callout)
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Shared Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Enter a prompt", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isExecuting)
                    .accessibilityHint("The prompt is sent to the active profile in the shared session")

                HStack(spacing: Spacing.small) {
                    Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                        .buttonStyle(.glass)
                        .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
                        .disabled(model.isExecuting)

                    Button(
                        model.isStopping ? "Stopping…" : (model.isRunning ? "Stop" : "Run Session"),
                        systemImage: model.isStopping ? "hourglass" : (model.isRunning ? "stop.fill" : "play.fill"),
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
                    DynamicProfileWorkflowTurnView(turn: turn)

                    if turn.id != model.turns.first?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var ownershipBoundary: some View {
        DisclosureGroup("About Dynamic Profiles", isExpanded: $isBoundaryExpanded) {
            Text(
                """
                The app chooses the stage and model. DynamicProfile re-evaluates before each request, while LanguageModelSession \
                keeps one transcript. The tool reads labeled sample text; it does not inspect this repository, GitHub, or a real build.
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
