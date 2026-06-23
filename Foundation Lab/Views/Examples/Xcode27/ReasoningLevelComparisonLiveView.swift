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

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Compare requested reasoning budgets")
                        .font(.title2.bold())
                    Text("Send one prompt through fresh light, moderate, and deep Private Cloud Compute sessions.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                runtimeStatus
                promptSection

                if let errorMessage = model.errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
                }

                resultsSection
                measurementBoundary
                CodeDisclosure(code: selectedLevel.code)
            }
            .frame(maxWidth: 900, alignment: .leading)
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

    private var runtimeStatus: some View {
        Xcode27Section(String(localized: "Runtime")) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("Private Cloud Compute", systemImage: "icloud")
                    .font(.callout)

                if let issue = model.readinessIssue {
                    Label(issue, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                } else {
                    Label("Available and reporting reasoning support", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Text("Running the comparison makes three separate PCC requests and consumes the corresponding usage quota.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Shared Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Enter one prompt for all three levels", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(4...8)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityHint("The same prompt is sent to a new session for each reasoning level")

                HStack {
                    Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                        .buttonStyle(.borderless)
                        .padding(.vertical, Spacing.medium)
                        .contentShape(.rect)

                    Spacer()

                    Button(
                        model.isRunning ? "Stop" : "Run 3 Levels",
                        systemImage: model.isRunning ? "stop.fill" : "play.fill",
                        action: toggleRun
                    )
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(!model.isRunning && !model.canRun)
                }
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

    private var measurementBoundary: some View {
        Xcode27Section(String(localized: "Interpretation")) {
            Text(
                """
                Token counts come from Response.Usage. Elapsed time is this app's wall-clock observation of sequential requests. \
                Network conditions, service load, caching, generation variance, and run order are uncontrolled, so these results do \
                not establish that a reasoning level caused a latency or quality difference.
                """
            )
            .font(.callout)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
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
