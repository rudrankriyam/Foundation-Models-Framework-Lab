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
    @State private var currentPrompt = "Inspect the current Foundation Models runtime."
    @State private var report = ModelRuntimeReport.placeholder
    @State private var isInspecting = false

    var body: some View {
        ExampleViewBase(
            title: "Model Runtime",
            description: "Compare the system model with Xcode 27 runtime capabilities",
            defaultPrompt: "Inspect the current Foundation Models runtime.",
            currentPrompt: $currentPrompt,
            isRunning: isInspecting,
            errorMessage: nil,
            codeExample: codeExample,
            onRun: inspectRuntime,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("System Model") {
                    VStack(spacing: 0) {
                        Xcode27StatusRow(
                            title: "Context",
                            value: "\(report.systemContextSize) tokens",
                            systemImage: "text.page"
                        )

                        Divider()

                        Xcode27StatusRow(
                            title: "Availability",
                            value: report.systemAvailability,
                            systemImage: report.systemAvailable ? "checkmark.circle.fill" : "xmark.circle.fill",
                            tint: report.systemAvailable ? .green : .orange
                        )
                    }
                }

                Xcode27Section("Capabilities") {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(report.capabilities, id: \.name) { capability in
                            Xcode27InfoRow(
                                title: capability.name,
                                detail: capability.isSupported ? "Supported by this model surface." : "Not reported by this model surface.",
                                systemImage: capability.isSupported ? "checkmark.circle" : "circle",
                                tint: capability.isSupported ? .green : .secondary
                            )
                            .padding(.vertical, Spacing.small)

                            if capability.name != report.capabilities.last?.name {
                                Divider()
                            }
                        }
                    }
                }

                Xcode27Section("Runtime Note") {
                    Text(report.runtimeNote)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .task {
                inspectRuntime()
            }
        }
    }

    private func inspectRuntime() {
        isInspecting = true
        defer { isInspecting = false }

        let systemModel = SystemLanguageModel.default
        let availability = systemModel.availability
        let availabilityText: String
        let isAvailable: Bool

        switch availability {
        case .available:
            availabilityText = "Available"
            isAvailable = true
        case .unavailable(let reason):
            availabilityText = unavailableReasonDescription(reason)
            isAvailable = false
        }

        var capabilities = [
            ModelCapabilityRow(name: "Vision", isSupported: false),
            ModelCapabilityRow(name: "Guided generation", isSupported: false),
            ModelCapabilityRow(name: "Reasoning", isSupported: false),
            ModelCapabilityRow(name: "Tool calling", isSupported: false)
        ]

        #if compiler(>=6.4)
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let modelCapabilities = systemModel.capabilities
            capabilities = [
                ModelCapabilityRow(name: "Vision", isSupported: modelCapabilities.contains(.vision)),
                ModelCapabilityRow(name: "Guided generation", isSupported: modelCapabilities.contains(.guidedGeneration)),
                ModelCapabilityRow(name: "Reasoning", isSupported: modelCapabilities.contains(.reasoning)),
                ModelCapabilityRow(name: "Tool calling", isSupported: modelCapabilities.contains(.toolCalling))
            ]
        }
        #endif

        report = ModelRuntimeReport(
            systemContextSize: systemModel.contextSize,
            systemAvailability: availabilityText,
            systemAvailable: isAvailable,
            capabilities: capabilities,
            runtimeNote: """
            PrivateCloudComputeLanguageModel is inspected separately because its context size is async and may require macOS/iOS 27 \
            runtime support plus service eligibility.
            """
        )
    }

    private func reset() {
        currentPrompt = ""
        report = .placeholder
    }

    private func unavailableReasonDescription(
        _ reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Device not eligible"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence not enabled"
        case .modelNotReady:
            return "Model not ready"
        @unknown default:
            return "Unavailable"
        }
    }

    private var codeExample: String {
        """
        let systemModel = SystemLanguageModel.default
        let contextSize = systemModel.contextSize

        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, *) {
            let capabilities = systemModel.capabilities
            capabilities.contains(.toolCalling)
            capabilities.contains(.vision)
        }
        """
    }
}

private struct ModelRuntimeReport {
    var systemContextSize: Int
    var systemAvailability: String
    var systemAvailable: Bool
    var capabilities: [ModelCapabilityRow]
    var runtimeNote: String

    static let placeholder = ModelRuntimeReport(
        systemContextSize: 4_096,
        systemAvailability: "Not inspected yet",
        systemAvailable: false,
        capabilities: [
            ModelCapabilityRow(name: "Vision", isSupported: false),
            ModelCapabilityRow(name: "Guided generation", isSupported: false),
            ModelCapabilityRow(name: "Reasoning", isSupported: false),
            ModelCapabilityRow(name: "Tool calling", isSupported: false)
        ],
        runtimeNote: "Tap Run to inspect the local runtime."
    )
}

private struct ModelCapabilityRow {
    let name: String
    let isSupported: Bool
}

#Preview {
    NavigationStack {
        ModelRuntimeView()
    }
}
