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
    @State private var report = PrivateCloudComputeReport.pending
    @State private var isInspecting = false
    @State private var inspectionID = UUID()
    @State private var errorMessage: String?
    @State private var inspectionTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Text("Probe PCC availability, quota, and context size")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: Spacing.small) {
                    Button(action: reset) {
                        Text("Reset")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)

                    Button(action: toggleInspection) {
                        Label(
                            isExecuting ? String(localized: "Stop") : String(localized: "Inspect"),
                            systemImage: isExecuting ? "stop.fill" : "magnifyingglass"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
                .controlSize(.large)

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                        .padding(Spacing.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08), in: .rect(cornerRadius: CornerRadius.medium))
                }

                Xcode27Section(String(localized: "Runtime Status")) {
                    VStack(spacing: 0) {
                        Xcode27StatusRow(
                            title: String(localized: "Availability"),
                            value: report.availability,
                            systemImage: report.availabilitySystemImage,
                            tint: report.availabilityTint
                        )

                        Divider()

                        Xcode27StatusRow(
                            title: String(localized: "Context Size"),
                            value: report.contextSize.map { String(localized: "\($0) tokens") }
                                ?? String(localized: "Unknown"),
                            systemImage: "text.page.badge.magnifyingglass"
                        )

                        Divider()

                        Xcode27StatusRow(
                            title: String(localized: "Quota"),
                            value: report.quota,
                            systemImage: "gauge.with.dots.needle.67percent",
                            tint: report.quotaLimitReached ? .red : .blue
                        )
                    }
                }

                Xcode27Section(String(localized: "Supported Languages")) {
                    Text(report.supportedLanguages)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                CodeDisclosure(code: codeExample)
            }
            .frame(maxWidth: 900, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Private Cloud")
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .onDisappear(perform: cancelInspection)
    }
}

private extension PrivateCloudComputeView {
    var isExecuting: Bool {
        isInspecting || inspectionTask != nil
    }

    func toggleInspection() {
        if isExecuting {
            cancelInspection()
            return
        }

        inspectionTask = Task {
            await inspect()
            guard !Task.isCancelled else { return }
            inspectionTask = nil
        }
    }

    func cancelInspection() {
        inspectionID = UUID()
        inspectionTask?.cancel()
        inspectionTask = nil
        isInspecting = false
    }

    func inspect() async {
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
            availabilityText = String(localized: "Available")
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
                supportedLanguages: languages.isEmpty ? String(localized: "No languages reported yet.") : languages
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
                supportedLanguages: languages.isEmpty ? String(localized: "No languages reported yet.") : languages
            )
            errorMessage = error.localizedDescription
        }
        #else
        guard inspectionID == id else { return }
        report = .unsupported
        errorMessage = String(localized: "PrivateCloudComputeLanguageModel requires the Xcode 27 SDK.")
        #endif
    }

    func reset() {
        cancelInspection()
        report = .pending
        errorMessage = nil
    }

    #if compiler(>=6.4)
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    func unavailableReasonDescription(
        _ reason: PrivateCloudComputeLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return String(localized: "Device not eligible")
        case .systemNotReady:
            return String(localized: "System not ready")
        @unknown default:
            return String(localized: "Unavailable")
        }
    }

    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    func quotaDescription(
        _ quotaUsage: PrivateCloudComputeLanguageModel.QuotaUsage
    ) -> String {
        switch quotaUsage.status {
        case .belowLimit(let belowLimit):
            return belowLimit.isApproachingLimit
                ? String(localized: "Below limit, approaching cap")
                : String(localized: "Below limit")
        case .limitReached:
            if let resetDate = quotaUsage.resetDate {
                return String(localized: "Limit reached. Resets \(resetDate.formatted(date: .abbreviated, time: .shortened))")
            }
            return String(localized: "Limit reached")
        @unknown default:
            return String(localized: "Unknown")
        }
    }
    #endif

    var codeExample: String {
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
    var hasBeenInspected = true
    var contextSize: Int?
    var quota: String
    var quotaLimitReached: Bool
    var supportedLanguages: String

    var availabilitySystemImage: String {
        if !hasBeenInspected {
            "questionmark.circle"
        } else if isAvailable {
            "checkmark.icloud.fill"
        } else {
            "icloud.slash"
        }
    }

    var availabilityTint: Color {
        if !hasBeenInspected {
            .secondary
        } else {
            isAvailable ? .green : .orange
        }
    }

    static let pending = PrivateCloudComputeReport(
        availability: String(localized: "Not inspected yet"),
        isAvailable: false,
        hasBeenInspected: false,
        contextSize: nil,
        quota: String(localized: "Not inspected yet"),
        quotaLimitReached: false,
        supportedLanguages: String(localized: "Not inspected yet")
    )

    static let unsupported = PrivateCloudComputeReport(
        availability: String(localized: "Requires OS 27 runtime"),
        isAvailable: false,
        contextSize: nil,
        quota: String(localized: "Requires OS 27 runtime"),
        quotaLimitReached: false,
        supportedLanguages: String(
            localized: "PrivateCloudComputeLanguageModel is gated to iOS, macOS, visionOS, and watchOS 27."
        )
    )
}

#Preview {
    NavigationStack {
        PrivateCloudComputeView()
    }
}
