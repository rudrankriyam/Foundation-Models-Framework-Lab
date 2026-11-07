//
//  WatchQuotaSection.swift
//  Foundation Lab Watch
//

import FoundationModels
import SwiftUI

struct WatchQuotaSection: View {
    let quotaUsage: PrivateCloudComputeLanguageModel.QuotaUsage

    var body: some View {
        Section("Quota") {
            Label(
                statusText,
                systemImage: quotaUsage.isLimitReached
                    ? "gauge.with.dots.needle.100percent"
                    : "gauge.with.dots.needle.33percent"
            )

            if let resetDate = quotaUsage.resetDate {
                LabeledContent("Resets") {
                    Text(resetDate, style: .relative)
                }
            }

            if let suggestion = quotaUsage.limitIncreaseSuggestion {
                Button("Increase Limit") {
                    suggestion.show()
                }
            }
        }
    }

    private var statusText: String {
        switch quotaUsage.status {
        case .belowLimit(let belowLimit):
            if belowLimit.isApproachingLimit {
                String(localized: "Approaching limit")
            } else {
                String(localized: "Below limit")
            }
        case .limitReached:
            String(localized: "Limit reached")
        @unknown default:
            String(localized: "Unknown")
        }
    }
}
