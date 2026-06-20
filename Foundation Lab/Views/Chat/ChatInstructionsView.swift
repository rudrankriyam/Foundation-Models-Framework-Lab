//
//  ChatInstructionsView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 27/10/2025.
//

import SwiftUI

struct ChatInstructionsView: View {
    enum Constants {
        static let defaultTopKValue = 50
        static let topKMinValue = 1
        static let topKMaxValue = 100
        static let textFieldWidth: CGFloat = 100
        static let samplingConfigBackgroundColor = Color.blue.opacity(0.05)
    }
    @Binding var viewModel: ChatViewModel

    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var clampedTopKSamplingValue: Binding<Int> {
        Binding(
            get: { viewModel.topKSamplingValue },
            set: { viewModel.topKSamplingValue = min(Constants.topKMaxValue, max(Constants.topKMinValue, $0)) }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.large) {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Customize AI Behavior")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Provide specific instructions to guide how the AI should respond. These instructions will " +
                             "apply to all new conversations.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    samplingStrategySection

                    // Guardrails Toggle
                    PermissiveGuardrailsToggle(isEnabled: $viewModel.usePermissiveGuardrails)

                    TextEditor(text: $viewModel.instructions)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(Spacing.medium)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(.rect(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )

                    Spacer(minLength: 20)

                    // Navigation Link Section
                    VStack(spacing: 0) {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .frame(height: 1)
                            .padding(.bottom, Spacing.medium)

                        Text("More Options")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.bottom, Spacing.small)

                        // Feedback Link
                        NavigationLink(destination: FeedbackView(viewModel: viewModel, isPresented: .constant(true))) {
                            HStack {
                                Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                                    .foregroundStyle(.tint)
                                Text("Provide Feedback")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(Spacing.medium)
                            .background(Color.gray.opacity(0.05))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }
                }
                .padding(Spacing.medium)
            }
            .navigationTitle("Instructions")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private var samplingStrategySection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text("Sampling Strategy")
                .font(.headline)
                .padding(.horizontal, Spacing.medium)

            Picker("Sampling Strategy", selection: $viewModel.samplingStrategy) {
                Text("Default").tag(SamplingStrategy.default)
                Text("Greedy").tag(SamplingStrategy.greedy)
                Text("Top-K").tag(SamplingStrategy.sampling)
                Text("Top-P").tag(SamplingStrategy.probabilityThreshold)
            }
            .pickerStyle(.menu)
            .padding(.horizontal, Spacing.medium)

            Text("""
                Default: Uses system defaults for optimal balance.
                Greedy: Always chooses the most likely token (deterministic).
                Top-K: Samples from a fixed number of likely tokens.
                Top-P: Samples from the smallest set that reaches a probability threshold.
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Spacing.medium)

            if viewModel.samplingStrategy == .sampling
                || viewModel.samplingStrategy == .probabilityThreshold {
                samplingConfigurationView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.medium)
        .background(Color.tertiaryBackgroundColor, in: .rect(cornerRadius: CornerRadius.large))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(.quaternary, lineWidth: 1)
        }
    }

    private var samplingConfigurationView: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if viewModel.samplingStrategy == .sampling {
                HStack {
                    Text("Top-K Sampling Value")
                        .font(.subheadline)
                    Spacer()
                    TextField("Value", value: clampedTopKSamplingValue, formatter: NumberFormatter())
                        .textFieldStyle(.roundedBorder)
                        .frame(width: Constants.textFieldWidth)
                }
            } else {
                LabeledContent("Top-P Threshold") {
                    Text(viewModel.probabilityThresholdSamplingValue, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }
                Slider(
                    value: $viewModel.probabilityThresholdSamplingValue,
                    in: 0.05...1,
                    step: 0.05
                )
            }

            Toggle("Use Fixed Seed", isOn: $viewModel.useFixedSeed)
                .font(.subheadline)

            Text(samplingHelpText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if viewModel.useFixedSeed {
                HStack {
                    Image(systemName: "dice")
                        .foregroundStyle(.secondary)
                    Text("Using fixed seed for reproducible variations")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, Spacing.small)
            }
        }
        .padding(Spacing.medium)
        .background(Constants.samplingConfigBackgroundColor)
        .clipShape(.rect(cornerRadius: 12))
    }

    private var samplingHelpText: String {
        if viewModel.samplingStrategy == .sampling {
            return "Top-K limits sampling to a fixed number of likely tokens. "
                + "Lower values are more focused; higher values allow more variation."
        }

        return "Top-P includes the smallest group of likely tokens whose combined probability reaches this threshold."
    }
}

#Preview {
    ChatInstructionsView(viewModel: .constant(.init()),
        onApply: { }
    )
}
