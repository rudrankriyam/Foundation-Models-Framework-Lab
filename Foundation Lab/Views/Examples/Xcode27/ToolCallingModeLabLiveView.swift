//
//  ToolCallingModeLabLiveView.swift
//  FoundationLab
//

#if compiler(>=6.4)
import SwiftUI

@available(iOS 27.0, macOS 27.0, visionOS 27.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ToolCallingModeLabLiveView: View {
    @State private var model = ToolCallingModeLabViewModel()
    @State private var selectedMode = ToolCallingExperimentMode.allowed

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text("Observe tool policy in the transcript")
                        .font(.title2.bold())
                    Text("Run one prompt with allowed, required, and disallowed tool calling against a read-only local fixture.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                runtimeStatus
                localFixture
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
                policyBoundary
                CodeDisclosure(code: selectedMode.code)
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        #if os(iOS)
        .scrollDismissesKeyboard(.interactively)
        #endif
        .navigationTitle("Tool Calling Modes")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle("Compare real calls and outputs")
        #endif
        .onChange(of: model.activeMode) { _, mode in
            if let mode {
                selectedMode = mode
            }
        }
        .onDisappear(perform: model.cancelRun)
    }

    private var runtimeStatus: some View {
        Xcode27Section(String(localized: "Runtime")) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label("On-device system language model", systemImage: "apple.intelligence")
                    .font(.callout)

                if let issue = model.readinessIssue {
                    Label(issue, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                } else {
                    Label("Available and reporting tool-calling support", systemImage: "checkmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var localFixture: some View {
        Xcode27Section(String(localized: "Read-only Local Tool")) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                LabeledContent("Tool", value: "read_local_release_record")
                LabeledContent("Fixture record", value: "foundation-lab")
                Text("The tool reads deterministic sample text bundled with this lab. It performs no network request and changes no data.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
        }
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Shared Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Ask about the local fixture", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(3...7)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isRunning || model.isStoppingRun)
                    .accessibilityHint("The same prompt is sent to a new session for each tool-calling mode")

                HStack {
                    Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                        .buttonStyle(.borderless)
                        .padding(.vertical, Spacing.medium)
                        .contentShape(.rect)
                        .disabled(model.isRunning || model.isStoppingRun)

                    Spacer()

                    Button(
                        model.isStoppingRun ? "Stopping…" : (model.isRunning ? "Stop" : "Run 3 Modes"),
                        systemImage: model.isStoppingRun ? "hourglass" : (model.isRunning ? "stop.fill" : "play.fill"),
                        action: toggleRun
                    )
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                    .disabled(model.isStoppingRun || (!model.isRunning && !model.canRun))
                }
            }
        }
    }

    private var resultsSection: some View {
        Xcode27Section(String(localized: "Observed Results")) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Picker("Tool-calling mode", selection: $selectedMode) {
                    ForEach(ToolCallingExperimentMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if let result = model.results.first(where: { $0.mode == selectedMode }) {
                    ToolCallingModeResultView(result: result)
                }
            }
        }
    }

    private var policyBoundary: some View {
        Xcode27Section(String(localized: "Interpretation")) {
            Text(
                """
                Transcript calls and outputs come from the real LanguageModelSession transcript. Local executions are recorded inside \
                the deterministic tool itself; the model response is shown separately. Allowed permits but does not require a call. \
                Required forces the first call, then this lab switches to allowed so the model can finish its answer.
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
