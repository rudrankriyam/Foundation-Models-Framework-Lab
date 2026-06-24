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
    @State private var isLocalFixtureExpanded = false
    @State private var isPolicyBoundaryExpanded = false

    var body: some View {
        @Bindable var model = model

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.xLarge) {
                if let issue = model.readinessIssue {
                    readinessIssue(issue)
                }

                localFixture
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

                policyBoundary
                CodeDisclosure(code: selectedMode.code)
            }
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
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

    private func readinessIssue(_ issue: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("System model unavailable")
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

    private var localFixture: some View {
        DisclosureGroup("Read-only Local Tool", isExpanded: $isLocalFixtureExpanded) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                LabeledContent("Tool", value: "read_local_release_record")
                LabeledContent("Sample record", value: "foundation-lab")
                Text("The tool reads deterministic sample text bundled with this lab. It performs no network request and changes no data.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, Spacing.small)
            .font(.callout)
        }
        .font(.callout)
    }

    private var promptSection: some View {
        Xcode27Section(String(localized: "Shared Prompt")) {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                TextField("Ask about the sample record", text: Bindable(model).prompt, axis: .vertical)
                    .lineLimit(3...7)
                    .textFieldStyle(.roundedBorder)
                    .disabled(model.isRunning || model.isStoppingRun)
                    .accessibilityHint("The same prompt is sent to a new session for each tool-calling mode")

                Button("Reset", systemImage: "arrow.counterclockwise", action: model.reset)
                    .buttonStyle(.borderless)
                    .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
                    .disabled(model.isRunning || model.isStoppingRun)

                Button(
                    model.isStoppingRun ? "Stopping…" : (model.isRunning ? "Stop" : "Run 3 Modes"),
                    systemImage: model.isStoppingRun ? "hourglass" : (model.isRunning ? "stop.fill" : "play.fill"),
                    action: toggleRun
                )
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: FoundationLabLayout.minimumTouchTarget)
                .disabled(model.isStoppingRun || (!model.isRunning && !model.canRun))
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
        DisclosureGroup("About Tool Policies", isExpanded: $isPolicyBoundaryExpanded) {
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
