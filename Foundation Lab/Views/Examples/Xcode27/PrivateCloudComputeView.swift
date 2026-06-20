//
//  PrivateCloudComputeView.swift
//  FoundationLab
//
//  Created by Codex on 6/8/26.
//

import Foundation
import FoundationModels
import SwiftUI

struct PrivateCloudComputeView: View {
    @State private var currentPrompt = "Inspect Private Cloud Compute availability."
    @State private var report = PrivateCloudComputeReport.pending
    @State private var isInspecting = false
    @State private var inspectionID = UUID()
    @State private var errorMessage: String?

    var body: some View {
        ExampleViewBase(
            title: "Private Cloud",
            description: "Probe PCC availability, quota, and context size",
            currentPrompt: $currentPrompt,
            isRunning: isInspecting,
            errorMessage: errorMessage,
            codeExample: codeExample,
            onRun: inspect,
            onReset: reset
        ) {
            VStack(spacing: Spacing.medium) {
                Xcode27Section("Runtime Status") {
                    VStack(spacing: 0) {
                        Xcode27StatusRow(
                            title: "Availability",
                            value: report.availability,
                            systemImage: report.isAvailable ? "checkmark.icloud.fill" : "icloud.slash",
                            tint: report.isAvailable ? .green : .orange
                        )

                        Divider()

                        Xcode27StatusRow(
                            title: "Context Size",
                            value: report.contextSize.map { "\($0) tokens" } ?? "Unknown",
                            systemImage: "text.page.badge.magnifyingglass"
                        )

                        Divider()

                        Xcode27StatusRow(
                            title: "Quota",
                            value: report.quota,
                            systemImage: "gauge.with.dots.needle.67percent",
                            tint: report.quotaLimitReached ? .red : .blue
                        )
                    }
                }

                Xcode27Section("Supported Languages") {
                    Text(report.supportedLanguages)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func inspect() async {
        let id = UUID()
        inspectionID = id
        isInspecting = true
        errorMessage = nil

        defer {
            if inspectionID == id {
                isInspecting = false
            }
        }

        #if compiler(>=6.4)
        guard #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) else {
            guard inspectionID == id else { return }
            report = .unsupported
            return
        }

        let model = PrivateCloudComputeLanguageModel()
        let availabilityText: String

        switch model.availability {
        case .available:
            availabilityText = "Available"
        case .unavailable(let reason):
            availabilityText = unavailableReasonDescription(reason)
        }

        let quotaUsage = model.quotaUsage
        let quotaText = quotaDescription(quotaUsage)
        let languages = model.supportedLanguages
            .map { $0.minimalIdentifier }
            .sorted()
            .joined(separator: ", ")

        do {
            let contextSize = try await model.contextSize
            try Task.checkCancellation()
            guard inspectionID == id else { return }
            report = PrivateCloudComputeReport(
                availability: availabilityText,
                isAvailable: model.isAvailable,
                contextSize: contextSize,
                quota: quotaText,
                quotaLimitReached: quotaUsage.isLimitReached,
                supportedLanguages: languages.isEmpty ? "No languages reported yet." : languages
            )
        } catch is CancellationError {
            return
        } catch {
            guard inspectionID == id else { return }
            report = PrivateCloudComputeReport(
                availability: availabilityText,
                isAvailable: model.isAvailable,
                contextSize: nil,
                quota: quotaText,
                quotaLimitReached: quotaUsage.isLimitReached,
                supportedLanguages: languages.isEmpty ? "No languages reported yet." : languages
            )
            errorMessage = error.localizedDescription
        }
        #else
        guard inspectionID == id else { return }
        report = .unsupported
        errorMessage = "PrivateCloudComputeLanguageModel requires the Xcode 27 SDK."
        #endif
    }

    private func reset() {
        inspectionID = UUID()
        isInspecting = false
        currentPrompt = ""
        report = .pending
        errorMessage = nil
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    private func unavailableReasonDescription(
        _ reason: PrivateCloudComputeLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Device not eligible"
        case .systemNotReady:
            return "System not ready"
        @unknown default:
            return "Unavailable"
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    private func quotaDescription(
        _ quotaUsage: PrivateCloudComputeLanguageModel.QuotaUsage
    ) -> String {
        switch quotaUsage.status {
        case .belowLimit(let belowLimit):
            return belowLimit.isApproachingLimit ? "Below limit, approaching cap" : "Below limit"
        case .limitReached:
            if let resetDate = quotaUsage.resetDate {
                return "Limit reached. Resets \(resetDate.formatted(date: .abbreviated, time: .shortened))"
            }
            return "Limit reached"
        @unknown default:
            return "Unknown"
        }
    }
    #endif

    private var codeExample: String {
        """
        if #available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *) {
            let model = PrivateCloudComputeLanguageModel()

            model.availability
            model.quotaUsage
            model.isAvailable
            let contextSize = try await model.contextSize
        }
        """
    }
}

private struct PrivateCloudComputeReport {
    var availability: String
    var isAvailable: Bool
    var contextSize: Int?
    var quota: String
    var quotaLimitReached: Bool
    var supportedLanguages: String

    static let pending = PrivateCloudComputeReport(
        availability: "Not inspected yet",
        isAvailable: false,
        contextSize: nil,
        quota: "Not inspected yet",
        quotaLimitReached: false,
        supportedLanguages: "Tap Run to inspect PCC language support."
    )

    static let unsupported = PrivateCloudComputeReport(
        availability: "Requires OS 27 runtime",
        isAvailable: false,
        contextSize: nil,
        quota: "Requires OS 27 runtime",
        quotaLimitReached: false,
        supportedLanguages: "PrivateCloudComputeLanguageModel is gated to iOS, macOS, visionOS, and watchOS 27."
    )
}

#Preview {
    NavigationStack {
        PrivateCloudComputeView()
    }
}
