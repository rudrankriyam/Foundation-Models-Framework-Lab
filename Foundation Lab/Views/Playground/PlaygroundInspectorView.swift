import FoundationLabCore
import SwiftUI

struct PlaygroundInspectorView: View {
    @Bindable var experimentStore: ExperimentStore
    @Bindable var viewModel: ChatViewModel
    let applyConfiguration: () -> Void

    var body: some View {
        Form {
            Section("Experiment") {
                TextField("Name", text: $experimentStore.activeExperiment.name)
                TextField("Description", text: $experimentStore.activeExperiment.summary, axis: .vertical)
                    .lineLimit(2...4)

                LabeledContent("Level") {
                    Label(
                        experimentStore.activeExperiment.level.displayName,
                        systemImage: experimentStore.activeExperiment.level.systemImage
                    )
                }
            }

            Section("Model") {
                Picker("Runtime", selection: runtimeBinding) {
                    ForEach(FoundationLabModelRuntime.allCases, id: \.self) { runtime in
                        Label(runtime.displayName, systemImage: runtime.systemImage)
                            .tag(runtime)
                            .disabled(runtime == .privateCloudCompute && !viewModel.canSelectPrivateCloudCompute)
                    }
                }

                Picker("Reasoning", selection: reasoningBinding) {
                    ForEach(FoundationLabReasoningLevel.allCases, id: \.self) { level in
                        Label(level.displayName, systemImage: level.systemImage)
                            .tag(level)
                    }
                }
                .disabled(!canDraftReasoning || viewModel.isLoading)
            }
            .disabled(viewModel.isLoading)

            Section("Generation") {
                Picker("Sampling", selection: samplingBinding) {
                    Text("Default").tag(SamplingStrategy.default)
                    Text("Greedy").tag(SamplingStrategy.greedy)
                    Text("Top-K").tag(SamplingStrategy.sampling)
                    Text("Top-P").tag(SamplingStrategy.probabilityThreshold)
                }

                if samplingBinding.wrappedValue == .sampling {
                    Stepper("Top-K: \(topKBinding.wrappedValue)", value: topKBinding, in: 1...100)
                    Toggle("Use Fixed Seed", isOn: fixedSeedBinding)
                } else if samplingBinding.wrappedValue == .probabilityThreshold {
                    LabeledContent("Top-P") {
                        Text(
                            topPBinding.wrappedValue,
                            format: .number.precision(.fractionLength(2))
                        )
                        .monospacedDigit()
                    }
                    Slider(
                        value: topPBinding,
                        in: 0.05...1,
                        step: 0.05
                    )
                    .accessibilityLabel("Top-P")
                    .accessibilityValue(
                        topPBinding.wrappedValue.formatted(
                            .number.precision(.fractionLength(2))
                        )
                    )
                    Toggle("Use Fixed Seed", isOn: fixedSeedBinding)
                }

                TextField("Temperature", value: temperatureBinding, format: .number)
#if os(iOS)
                    .keyboardType(.decimalPad)
#endif
                TextField("Maximum response tokens", value: maximumTokensBinding, format: .number)
#if os(iOS)
                    .keyboardType(.numberPad)
#endif
            }
            .disabled(viewModel.isLoading)

            Section("Instructions") {
                TextField(
                    "Describe how the model should behave",
                    text: $experimentStore.activeExperiment.instructions,
                    axis: .vertical
                )
                    .lineLimit(4...10)
            }
            .disabled(viewModel.isLoading)

            Section("Tools") {
                ForEach(FoundationLabBuiltInTool.allCases) { tool in
                    Button {
                        experimentStore.updateActiveExperiment { configuration in
                            if let index = configuration.selectedTools.firstIndex(of: tool) {
                                configuration.selectedTools.remove(at: index)
                            } else {
                                configuration.selectedTools.append(tool)
                            }
                        }
                    } label: {
                        ToolSelectionLabel(
                            tool: tool,
                            isSelected: experimentStore.activeExperiment.selectedTools.contains(tool)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                }
            }

            Section {
                Button("Apply Configuration", systemImage: "checkmark", action: applyConfiguration)
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)

                Button("Save Experiment", systemImage: "square.and.arrow.down") {
                    applyConfiguration()
                    experimentStore.saveActiveExperiment()
                }
                .disabled(viewModel.isLoading)
            }

            Section("Swift") {
                CodeDisclosure(code: ExperimentCodeGenerator.code(for: exportConfiguration))
                ShareLink(item: ExperimentCodeGenerator.code(for: exportConfiguration)) {
                    Label("Share Swift Code", systemImage: "square.and.arrow.up")
                }
            }
        }
        .formStyle(.grouped)
    }
}

private extension PlaygroundInspectorView {
    private var runtimeBinding: Binding<FoundationLabModelRuntime> {
        Binding(
            get: { experimentStore.activeExperiment.modelRuntime },
            set: { runtime in
                guard !viewModel.isLoading else { return }
                experimentStore.updateActiveExperiment { configuration in
                    configuration.modelRuntime = runtime
                    if runtime == .onDevice {
                        configuration.reasoningLevel = .none
                    }
                }
            }
        )
    }

    private var reasoningBinding: Binding<FoundationLabReasoningLevel> {
        Binding(
            get: { experimentStore.activeExperiment.reasoningLevel },
            set: { level in
                guard !viewModel.isLoading, canDraftReasoning || level == .none else { return }
                experimentStore.updateActiveExperiment { configuration in
                    configuration.reasoningLevel = level
                }
            }
        )
    }

    private var exportConfiguration: FoundationLabExperimentConfiguration {
        experimentStore.activeExperiment
    }

    private var canDraftReasoning: Bool {
        experimentStore.activeExperiment.modelRuntime == .privateCloudCompute
            && viewModel.canSelectPrivateCloudCompute
    }

    private var samplingBinding: Binding<SamplingStrategy> {
        Binding(
            get: { samplingStrategy(for: generationOptions.sampling) },
            set: { strategy in
                let seed = fixedSeed(from: generationOptions.sampling)
                switch strategy {
                case .default:
                    updateSampling(nil)
                case .greedy:
                    updateSampling(.greedy)
                case .sampling:
                    updateSampling(.randomTop(50, seed: seed))
                case .probabilityThreshold:
                    updateSampling(.randomProbabilityThreshold(0.9, seed: seed))
                }
            }
        )
    }

    private var topKBinding: Binding<Int> {
        Binding(
            get: {
                if case .randomTop(let top, _) = generationOptions.sampling { return top }
                return 50
            },
            set: { top in
                updateSampling(
                    .randomTop(top, seed: fixedSeed(from: generationOptions.sampling))
                )
            }
        )
    }

    private var topPBinding: Binding<Double> {
        Binding(
            get: {
                if case .randomProbabilityThreshold(let threshold, _) = generationOptions.sampling {
                    return threshold
                }
                return 0.9
            },
            set: { threshold in
                updateSampling(
                    .randomProbabilityThreshold(
                        threshold,
                        seed: fixedSeed(from: generationOptions.sampling)
                    )
                )
            }
        )
    }

    private var fixedSeedBinding: Binding<Bool> {
        Binding(
            get: { fixedSeed(from: generationOptions.sampling) != nil },
            set: { usesFixedSeed in
                let seed = usesFixedSeed ? fixedSeed(from: generationOptions.sampling) ?? UInt64.random(in: .min ... .max) : nil
                switch generationOptions.sampling {
                case .randomTop(let top, _):
                    updateSampling(.randomTop(top, seed: seed))
                case .randomProbabilityThreshold(let threshold, _):
                    updateSampling(.randomProbabilityThreshold(threshold, seed: seed))
                case .greedy, nil:
                    break
                }
            }
        )
    }

    private var temperatureBinding: Binding<Double?> {
        Binding(
            get: { generationOptions.temperature },
            set: { temperature in
                updateTemperature(temperature)
            }
        )
    }

    private var maximumTokensBinding: Binding<Int?> {
        Binding(
            get: { generationOptions.maximumResponseTokens },
            set: { maximumResponseTokens in
                updateMaximumResponseTokens(maximumResponseTokens)
            }
        )
    }

    private var generationOptions: FoundationLabGenerationOptions {
        experimentStore.activeExperiment.generationOptions
    }

    private func updateSampling(
        _ sampling: FoundationLabGenerationOptions.SamplingMode?
    ) {
        let current = generationOptions
        setGenerationOptions(FoundationLabGenerationOptions(
            sampling: sampling,
            temperature: current.temperature,
            maximumResponseTokens: current.maximumResponseTokens
        ))
    }

    private func updateTemperature(_ temperature: Double?) {
        let current = generationOptions
        setGenerationOptions(FoundationLabGenerationOptions(
            sampling: current.sampling,
            temperature: temperature,
            maximumResponseTokens: current.maximumResponseTokens
        ))
    }

    private func updateMaximumResponseTokens(_ maximumResponseTokens: Int?) {
        let current = generationOptions
        setGenerationOptions(FoundationLabGenerationOptions(
            sampling: current.sampling,
            temperature: current.temperature,
            maximumResponseTokens: maximumResponseTokens
        ))
    }

    private func setGenerationOptions(_ options: FoundationLabGenerationOptions) {
        experimentStore.updateActiveExperiment { configuration in
            configuration.generationOptions = options
        }
    }

    private func samplingStrategy(
        for sampling: FoundationLabGenerationOptions.SamplingMode?
    ) -> SamplingStrategy {
        switch sampling {
        case nil:
            .default
        case .greedy:
            .greedy
        case .randomTop:
            .sampling
        case .randomProbabilityThreshold:
            .probabilityThreshold
        }
    }

    private func fixedSeed(
        from sampling: FoundationLabGenerationOptions.SamplingMode?
    ) -> UInt64? {
        switch sampling {
        case .randomTop(_, let seed), .randomProbabilityThreshold(_, let seed):
            seed
        case .greedy, nil:
            nil
        }
    }
}

private struct ToolSelectionLabel: View {
    let tool: FoundationLabBuiltInTool
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: tool.systemImage)
                .frame(width: 24)
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(tool.displayName)
                    .foregroundStyle(.primary)
                Text(tool.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.small)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                .accessibilityHidden(true)
        }
        .frame(minHeight: 44)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}
