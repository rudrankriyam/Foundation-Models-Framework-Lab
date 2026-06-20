//
//  ModelRuntimeView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import Foundation
import FoundationModels
import SwiftUI

struct ModelRuntimeView: View {
    private static let defaultPrompt = "Inspect the current Foundation Models runtime."

    @State private var currentPrompt = defaultPrompt
    @State private var report: ModelRuntimeReport?
    @State private var isInspecting = false
    @State private var errorMessage: String?
    @State private var inspectionID = UUID()

    var body: some View {
        ExampleViewBase(
            title: String(localized: "System Model"),
            description: String(localized: "Inspect this device's model and tokenize the prompt"),
            currentPrompt: $currentPrompt,
            isRunning: isInspecting,
            errorMessage: errorMessage,
            codeExample: codeExample,
            onRun: inspectRuntime,
            onReset: reset
        ) {
            VStack(spacing: Spacing.large) {
                if let report {
                    Xcode27Section(String(localized: "Current Device")) {
                        VStack(spacing: 0) {
                            Xcode27StatusRow(
                                title: String(localized: "Availability"),
                                value: report.availability,
                                systemImage: report.isAvailable ? "checkmark.circle.fill" : "exclamationmark.circle.fill",
                                tint: report.isAvailable ? .green : .orange
                            )

                            Divider()

                            Xcode27StatusRow(
                                title: String(localized: "Context size"),
                                value: tokenLabel(report.contextSize),
                                systemImage: "text.page"
                            )

                            Divider()

                            Xcode27StatusRow(
                                title: String(localized: "This prompt"),
                                value: report.promptTokenDescription,
                                systemImage: "number"
                            )
                        }
                    }

                    Xcode27Section(String(localized: "Model Capabilities")) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(report.capabilities) { capability in
                                Xcode27InfoRow(
                                    title: capability.name,
                                    detail: capability.detail,
                                    systemImage: capability.systemImage,
                                    tint: capability.tint
                                )
                                .padding(.vertical, Spacing.small)

                                if capability.id != report.capabilities.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView {
                        Label("Runtime Not Inspected", systemImage: "cpu")
                    } description: {
                        Text("Run the prompt to read availability, context size, tokenizer output, and capabilities from the system model.")
                    }
                }

                Xcode27Section(String(localized: "Scope")) {
                    Text(
                        String(
                            localized: """
                            These values describe SystemLanguageModel.default on this device. Private Cloud Compute is a separate \
                            language model with its own availability, quota, supported languages, and asynchronous context size.
                            """
                        )
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func inspectRuntime() async {
        let id = UUID()
        let prompt = currentPrompt
        inspectionID = id
        isInspecting = true
        errorMessage = nil
        report = nil

        defer {
            if inspectionID == id {
                isInspecting = false
            }
        }

        let model = SystemLanguageModel.default
        let availability = availabilityDescription(model.availability)
        let promptTokenDescription: String

        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            do {
                let promptTokens = try await model.tokenCount(for: prompt)
                try Task.checkCancellation()
                promptTokenDescription = tokenLabel(promptTokens)
            } catch is CancellationError {
                return
            } catch {
                guard inspectionID == id, currentPrompt == prompt else { return }
                promptTokenDescription = String(localized: "Tokenization failed")
                errorMessage = String(
                    localized: "The runtime was inspected, but the prompt could not be tokenized: \(error.localizedDescription)"
                )
            }
        } else {
            promptTokenDescription = String(localized: "Requires OS 26.4")
        }

        guard inspectionID == id, currentPrompt == prompt else { return }
        report = ModelRuntimeReport(
            contextSize: model.contextSize,
            availability: availability.text,
            isAvailable: availability.isAvailable,
            promptTokenDescription: promptTokenDescription,
            capabilities: capabilityRows(for: model)
        )
    }

    private func reset() {
        inspectionID = UUID()
        isInspecting = false
        currentPrompt = Self.defaultPrompt
        report = nil
        errorMessage = nil
    }

    private func availabilityDescription(
        _ availability: SystemLanguageModel.Availability
    ) -> (text: String, isAvailable: Bool) {
        switch availability {
        case .available:
            (String(localized: "Available"), true)
        case .unavailable(let reason):
            (unavailableReasonDescription(reason), false)
        }
    }

    private func unavailableReasonDescription(
        _ reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            String(localized: "Device not eligible")
        case .appleIntelligenceNotEnabled:
            String(localized: "Apple Intelligence not enabled")
        case .modelNotReady:
            String(localized: "Model not ready")
        @unknown default:
            String(localized: "Unavailable")
        }
    }

    private func capabilityRows(for model: SystemLanguageModel) -> [ModelCapabilityRow] {
        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let capabilities = model.capabilities
            return [
                ModelCapabilityRow(name: String(localized: "Vision"), isSupported: capabilities.contains(.vision)),
                ModelCapabilityRow(name: String(localized: "Guided generation"), isSupported: capabilities.contains(.guidedGeneration)),
                ModelCapabilityRow(name: String(localized: "Reasoning"), isSupported: capabilities.contains(.reasoning)),
                ModelCapabilityRow(name: String(localized: "Tool calling"), isSupported: capabilities.contains(.toolCalling))
            ]
        }
        #endif

        return [
            ModelCapabilityRow(name: String(localized: "Vision"), isSupported: nil),
            ModelCapabilityRow(name: String(localized: "Guided generation"), isSupported: nil),
            ModelCapabilityRow(name: String(localized: "Reasoning"), isSupported: nil),
            ModelCapabilityRow(name: String(localized: "Tool calling"), isSupported: nil)
        ]
    }

    private func tokenLabel(_ count: Int) -> String {
        count == 1 ? String(localized: "\(count) token") : String(localized: "\(count) tokens")
    }

    private var codeExample: String {
        """
        let model = SystemLanguageModel.default
        let availability = model.availability
        let contextSize = model.contextSize

        if #available(iOS 26.4, macOS 26.4, visionOS 26.4, *) {
            let promptTokens = try await model.tokenCount(for: prompt)
        }

        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let capabilities = model.capabilities
            capabilities.contains(.toolCalling)
            capabilities.contains(.vision)
        }
        """
    }
}

private struct ModelRuntimeReport {
    let contextSize: Int
    let availability: String
    let isAvailable: Bool
    let promptTokenDescription: String
    let capabilities: [ModelCapabilityRow]
}

private struct ModelCapabilityRow: Identifiable {
    let name: String
    let isSupported: Bool?

    var id: String { name }

    var detail: String {
        switch isSupported {
        case true:
            String(localized: "Reported by this model.")
        case false:
            String(localized: "Not reported by this model.")
        case nil:
            String(localized: "Capability inspection requires the Xcode 27 SDK and an OS 27 runtime.")
        }
    }

    var systemImage: String {
        switch isSupported {
        case true: "checkmark.circle"
        case false: "xmark.circle"
        case nil: "questionmark.circle"
        }
    }

    var tint: Color {
        switch isSupported {
        case true: .green
        case false: .secondary
        case nil: .secondary
        }
    }
}

#Preview {
    NavigationStack {
        ModelRuntimeView()
    }
}
