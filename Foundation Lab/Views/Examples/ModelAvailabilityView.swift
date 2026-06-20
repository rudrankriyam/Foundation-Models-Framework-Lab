//
//  ModelAvailabilityView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct ModelAvailabilityView: View {
  @State private var availabilityStatus = "Tap 'Check Availability' to verify Apple Intelligence status"
  @State private var isChecking = false
  @State private var isAvailable: Bool?

  var body: some View {
    ExampleViewBase(
      title: "Model Availability",
      description: "Check if Apple Intelligence is available on this device",
      currentPrompt: .constant(DefaultPrompts.modelAvailability),
      isRunning: isChecking,
      errorMessage: nil,
      codeExample: DefaultPrompts.modelAvailabilityCode,
      onRun: checkAvailability,
      onReset: resetStatus
    ) {
      VStack(spacing: Spacing.large) {
        // Status Card
        VStack(spacing: Spacing.medium) {
          Image(systemName: isAvailable == true ? "checkmark.circle.fill" :
                              isAvailable == false ? "xmark.circle.fill" : "questionmark.circle")
            .font(.largeTitle)
            .foregroundStyle(isAvailable == true ? .green : isAvailable == false ? .red : .gray)

          Text(availabilityStatus)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xxLarge)
        .background(Color.tertiaryBackgroundColor)
        .clipShape(.rect(cornerRadius: CornerRadius.large))

        // Info Section
        VStack(alignment: .leading, spacing: 12) {
          Label("Requirements", systemImage: "info.circle")
            .font(.headline)

          VStack(alignment: .leading, spacing: 8) {
            RequirementRow(
              icon: "iphone",
              text: "Compatible Apple device with Apple Silicon",
              isMet: isAvailable
            )

            RequirementRow(
              icon: "gear",
              text: "iOS 26.0+, macOS 26.0+, or visionOS 26.0+",
              isMet: isAvailable
            )

            RequirementRow(
              icon: "brain",
              text: "Apple Intelligence enabled in Settings",
              isMet: isAvailable
            )
          }
        }
        .padding()
        .background(Color.tertiaryBackgroundColor)
        .clipShape(.rect(cornerRadius: CornerRadius.large))
      }
    }
  }

  private func checkAvailability() async {
    isChecking = true
    defer { isChecking = false }
    isAvailable = nil

    let availability = CheckModelAvailabilityUseCase().execute()
    isAvailable = availability.isAvailable
    availabilityStatus = availabilityMessage(for: availability)
  }

  private func resetStatus() {
    availabilityStatus = "Tap 'Check Availability' to verify Apple Intelligence status"
    isAvailable = nil
    isChecking = false // Also reset the checking state
  }

  private func availabilityMessage(for result: ModelAvailabilityResult) -> String {
    guard !result.isAvailable else {
      return "✅ Apple Intelligence is available and ready to use!"
    }

    switch result.reason {
    case .deviceNotEligible:
      return "Apple Intelligence is not available because this device is not eligible. "
        + "Foundation Lab requires iOS 26.0+, macOS 26.0+, or visionOS 26.0+ "
        + "on supported Apple Intelligence hardware."
    case .appleIntelligenceNotEnabled:
      return "Apple Intelligence is not enabled. Turn it on in Settings, then try again."
    case .modelNotReady:
      return "Apple Intelligence is still preparing model assets on this device. Please wait a bit and try again."
    case .unknown, .none:
      return "Apple Intelligence is not available on this device right now. "
        + "This feature requires iOS 26.0+, macOS 26.0+, or visionOS 26.0+ "
        + "and a compatible Apple device with Apple Intelligence enabled."
    }
  }
}

// MARK: - Supporting Views

private struct RequirementRow: View {
  let icon: String
  let text: String
  let isMet: Bool?

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundStyle(isMet == true ? .green : isMet == false ? .red : .secondary)
        .frame(width: 24)

      Text(text)
        .font(.subheadline)
        .foregroundStyle(.primary)

      Spacer()

      if let isMet = isMet {
        Image(systemName: isMet ? "checkmark" : "xmark")
          .foregroundStyle(isMet ? .green : .red)
          .font(.caption)
      }
    }
  }
}

#Preview {
  NavigationStack {
    ModelAvailabilityView()
  }
}
