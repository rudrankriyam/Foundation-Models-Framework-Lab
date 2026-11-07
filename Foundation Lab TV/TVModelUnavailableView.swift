//
//  TVModelUnavailableView.swift
//  Foundation Lab TV
//

#if canImport(FoundationModels, _version: 2.2)
import Foundation
import FoundationModels
import SwiftUI

@available(tvOS 27.3, *)
struct TVModelUnavailableView: View {
    let reason: SystemLanguageModel.Availability.UnavailableReason

    var body: some View {
        ContentUnavailableView {
            Label("Model Unavailable", systemImage: "apple.intelligence")
        } description: {
            Text(message)
        }
    }

    private var message: String {
        switch reason {
        case .deviceNotEligible:
            String(localized: "This device does not support Apple Intelligence.")
        case .appleIntelligenceNotEnabled:
            String(localized: "Turn on Apple Intelligence in Settings, then try again.")
        case .modelNotReady:
            String(localized: "The on-device model is still preparing. Try again when Apple Intelligence is ready.")
        @unknown default:
            String(localized: "The on-device model is currently unavailable.")
        }
    }
}
#endif
