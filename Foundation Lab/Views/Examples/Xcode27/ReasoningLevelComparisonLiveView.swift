//
//  ReasoningLevelComparisonLiveView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ReasoningLevelComparisonLiveView: View {
    @State private var model = ReasoningLevelComparisonViewModel()
    @State private var selectedLevel = ReasoningComparisonLevel.moderate
    @State private var isComparisonNotesExpanded = false

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                if let issue = model.readinessIssue {
                    readinessIssue(issue)
                }

                promptSection

                if let errorMessage = model.errorMessage {
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                        .font(.callout)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
                        .accessibilityLabel("Error: \(errorMessage)")
                        .accessibilityElement(children: .combine)
                }

                if !model.results.isEmpty {
                    resultsSection
                }

                comparisonNotes
                CodeDisclosure(code: selectedLevel.code)
            }
            .frame(maxWidth: 760, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .navigationTitle("Reasoning Levels")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Inspect real responses and usage")
        #endif
        .onChange(of: model.activeLevel) { _, level in
            if let level {
                selectedLevel = level
            }
        }
        .onDisappear(perform: model.cancelRun)
    }

    private func readinessIssue(_ issue: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Private Cloud Compute unavailable")
                    .bold()
                Text(issue)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        }
        .font(.callout)
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
        .accessibilityElement(children: .combine)
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Shared Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Enter one prompt for all three levels", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(4...8)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isRunning || model.isStoppingRun)
                    .accessibilityHint("The same prompt is sent to a new session for each reasoning level")

                Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                    .buttonStyle(.borderless)
                    .frame(minHeight: 44)
                    .disabled(model.isRunning || model.isStoppingRun)

                Button(
                    model.isStoppingRun ? "Stopping…" : (model.isRunning ? "Stop" : "Run 3 Levels"),
                    systemImage: model.isStoppingRun ? "hourglass" : (model.isRunning ? "stop.fill" : "play.fill"),
                    action: toggleRun
                )
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 44)
                .disabled(model.isStoppingRun || (!model.isRunning && !model.canRun))
            }
        }
    }

    private var resultsSection: some View {
        Xcode27Section(String(localized: "Observed Results")) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Picker("Reasoning level", selection: $selectedLevel) {
                    ForEach(ReasoningComparisonLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                if let result = model.results.first(where: { $0.level == selectedLevel }) {
                    ReasoningComparisonResultView(result: result)
                }
            }
        }
    }

    private var comparisonNotes: some View {
        DisclosureGroup("About This Comparison", isExpanded: $isComparisonNotesExpanded) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Text("Each comparison makes three separate PCC requests and consumes the corresponding usage quota.")
                Text(
                    """
                    Token counts come from Response.Usage. Elapsed time is this app's wall-clock observation of sequential requests. \
                    Network conditions, service load, caching, generation variance, and run order are uncontrolled, so these results do \
                    not establish that a reasoning level caused a latency or quality difference.
                    """
                )
            }
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
            model.startComparison()
        }
    }
}
#endif
