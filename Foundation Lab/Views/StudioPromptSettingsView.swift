//
//  StudioPromptSettingsView.swift
//  Foundation Lab
//

import SwiftUI

struct StudioPromptSettingsView: View {
    @Binding var promptText: String
    @Binding var selectedVariants: Set<StudioPromptVariant>

    let isRunning: Bool
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xLarge) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: Spacing.xLarge) {
                    promptEditor
                        .frame(minWidth: 320)

                    Divider()

                    variantSelector
                        .frame(minWidth: 300)
                }

                VStack(alignment: .leading, spacing: Spacing.xLarge) {
                    promptEditor
                    Divider()
                    variantSelector
                }
            }

            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("Run Configuration")
                    .font(.headline)

                VStack(spacing: 0) {
                    parameterRow(title: "Execution", value: "Sequential local runs")
                    parameterRow(title: "Selected Variants", value: "\(selectedVariants.count)")
                    parameterRow(title: "Prompt Characters", value: "\(promptText.count)")
                    parameterRow(title: "Result Capture", value: "Output, latency, token count")
                }
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.callout)
                    .foregroundStyle(.red)
            }
        }
    }

    private var promptEditor: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Label("Base Prompt", systemImage: "text.quote")
                .font(.headline)

            TextField(
                "Enter your prompt...",
                text: $promptText,
                axis: .vertical
            )
            .lineLimit(6...12)
            .textFieldStyle(.roundedBorder)
            .disabled(isRunning)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var variantSelector: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Label("Variants", systemImage: "square.stack.3d.up")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(StudioPromptVariant.allCases) { variant in
                    Toggle(isOn: variantBinding(for: variant)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(variant.title)
                            Text(variant.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .disabled(isRunning)
                    .padding(.vertical, Spacing.small)

                    if variant != StudioPromptVariant.allCases.last {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func parameterRow(title: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        } label: {
            Text(title)
                .font(.callout)
        }
        .padding(.vertical, Spacing.small)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private func variantBinding(for variant: StudioPromptVariant) -> Binding<Bool> {
        Binding {
            selectedVariants.contains(variant)
        } set: { isSelected in
            if isSelected {
                selectedVariants.insert(variant)
            } else {
                selectedVariants.remove(variant)
            }
        }
    }
}
