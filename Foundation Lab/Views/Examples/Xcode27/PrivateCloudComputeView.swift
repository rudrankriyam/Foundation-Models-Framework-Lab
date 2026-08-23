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
                Text("Inspect Private Cloud Compute availability, usage quota, context size, and language support.")
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
                    Label {
                        Text(errorMessage)
                            .foregroundStyle(.primary)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                    .font(.callout)
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
            .frame(maxWidth: FoundationLabLayout.readableContentWidth, alignment: .leading)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Private Cloud Compute")
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

        do {
            let runtimeDetails = try await runtimeDetails(for: model)
            guard inspectionID == id else { return }
            report = PrivateCloudComputeReport(
                availability: availabilityText,
                isAvailable: model.isAvailable,
                contextSize: runtimeDetails.contextSize,
                quota: quotaText,
                quotaLimitReached: quotaUsage.isLimitReached,
                supportedLanguages: runtimeDetails.supportedLanguages
            )
            errorMessage = runtimeDetails.errors.isEmpty
                ? nil
                : runtimeDetails.errors.joined(separator: "\n")
        } catch {
            return
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
    func runtimeDetails(
        for model: PrivateCloudComputeLanguageModel
    ) async throws(CancellationError) -> PrivateCloudComputeRuntimeDetails {
        var contextSize: Int?
        var supportedLanguages = String(localized: "Unavailable")
        var errors = [String]()

        do {
            contextSize = try await model.contextSize
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            errors.append(error.localizedDescription)
        }

        do {
            let languages = try await model.supportedLanguages
                .map { $0.minimalIdentifier }
                .sorted()
            supportedLanguages = languages.isEmpty
                ? String(localized: "No languages reported yet.")
                : languages.joined(separator: ", ")
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            errors.append(error.localizedDescription)
        }

        guard !Task.isCancelled else {
            throw CancellationError()
        }
        return PrivateCloudComputeRuntimeDetails(
            contextSize: contextSize,
            supportedLanguages: supportedLanguages,
            errors: errors
        )
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
            let supportedLanguages = try await model.supportedLanguages
        }
        """
    }
}

private struct PrivateCloudComputeRuntimeDetails {
    let contextSize: Int?
    let supportedLanguages: String
    let errors: [String]
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
