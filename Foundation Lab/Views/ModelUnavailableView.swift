//
//  ModelUnavailableView.swift
//  Foundation Lab
//
//  Created by Rudrank Riyam on 07/01/25.
//

import SwiftUI
import FoundationLabCore

struct ModelUnavailableView: View {
    let reason: ModelAvailabilityUnavailableReason?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ContentUnavailableView {
            Label("Apple Intelligence Is Unavailable", systemImage: "sparkles.slash")
        } description: {
            Text(descriptionText)
                .multilineTextAlignment(.center)
        } actions: {
            if showSettingsButton {
                Button("Open Settings") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
            }

            Button("Browse Foundation Lab") {
                dismiss()
            }
            .buttonStyle(.bordered)
        }
#if os(iOS)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
#else
        .frame(width: 500, height: 300)
#endif
    }

    private var descriptionText: String {
        guard let reason = reason else {
            return "The on-device model isn’t available right now. You can still browse recipes and saved runs."
        }

        switch reason {
        case .deviceNotEligible:
            return "This device doesn’t support Apple Intelligence, which Foundation Lab needs to run the " +
                   "on-device model. You can still browse recipes and saved runs."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings, then return to Foundation Lab and try again."
        case .modelNotReady:
            return "The on-device model is still downloading. You can browse Foundation Lab now and try again " +
                   "when the download finishes."
        case .unknown:
            return "Apple Intelligence is temporarily unavailable. You can browse recipes and saved runs, then " +
                   "try the model again later."
        }
    }

    private var showSettingsButton: Bool {
        guard let reason = reason else { return false }
        return reason == .appleIntelligenceNotEnabled
    }

    private func openSettings() {
#if os(iOS) || os(visionOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
#else
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.siri") {
            NSWorkspace.shared.open(url)
        }
#endif
    }
}

#Preview {
    ModelUnavailableView(reason: .deviceNotEligible)
}
