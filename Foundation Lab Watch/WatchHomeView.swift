//
//  WatchHomeView.swift
//  Foundation Lab Watch
//

import FoundationModels
import SwiftUI

struct WatchHomeView: View {
    @State private var model = PrivateCloudComputeLanguageModel()
    @State private var prompt = ""

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Foundation Lab")
                .navigationDestination(for: String.self) { prompt in
                    WatchResponseView(model: model, prompt: prompt)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.availability {
        case .available:
            List {
                Section("Prompt") {
                    TextField("Ask anything", text: $prompt)
                    NavigationLink(value: trimmedPrompt) {
                        Label("Send", systemImage: "paperplane.fill")
                    }
                    .disabled(trimmedPrompt.isEmpty)
                }

                Section("Presets") {
                    ForEach(WatchPromptPreset.allCases) { preset in
                        NavigationLink(value: preset.prompt) {
                            Label(preset.title, systemImage: preset.systemImage)
                        }
                    }
                }

                WatchQuotaSection(quotaUsage: model.quotaUsage)
            }
        case .unavailable(let reason):
            ContentUnavailableView {
                Label("Private Cloud Compute Unavailable", systemImage: "icloud.slash")
            } description: {
                Text(description(for: reason))
            }
        }
    }

    private var trimmedPrompt: String {
        prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func description(
        for reason: PrivateCloudComputeLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            String(localized: "This Apple Watch doesn't support Apple Intelligence.")
        case .systemNotReady:
            String(localized: "Private Cloud Compute isn't ready yet. Try again in a moment.")
        @unknown default:
            String(localized: "Private Cloud Compute isn't available right now.")
        }
    }
}
