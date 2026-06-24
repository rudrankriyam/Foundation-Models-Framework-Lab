//
//  ModelAvailabilityView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import FoundationLabCore
import SwiftUI

struct ModelAvailabilityView: View {
  @State private var availabilityStatus = "Run the check to see whether the on-device model is ready."
  @State private var isChecking = false
  @State private var isAvailable: Bool?

  var body: some View {
    ExampleViewBase(
      title: "Model Availability",
      description: "Check whether Apple Intelligence and the on-device model are ready.",
      currentPrompt: .constant(DefaultPrompts.modelAvailability),
      isRunning: isChecking,
      errorMessage: nil,
      codeExample: DefaultPrompts.modelAvailabilityCode,
      runLabel: "Check Availability",
      showsPrompt: false,
      onRun: checkAvailability,
      onReset: resetStatus
    ) {
      VStack(spacing: Spacing.large) {
        GroupBox("Availability") {
          HStack(alignment: .top, spacing: Spacing.medium) {
            Image(systemName: availabilitySymbol)
              .font(.title2)
              .foregroundStyle(availabilityColor)
              .accessibilityHidden(true)

            Text(availabilityStatus)
              .font(.body)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.top, Spacing.small)
        }

        GroupBox("Requirements") {
          VStack(alignment: .leading, spacing: Spacing.medium) {
            RequirementRow(
              icon: "iphone",
              text: "A device that supports Apple Intelligence"
            )

            RequirementRow(
              icon: "gear",
              text: "iOS 26, macOS 26, or visionOS 26 or later"
            )

            RequirementRow(
              icon: "brain",
              text: "Apple Intelligence turned on and its model downloaded"
            )
          }
          .padding(.top, Spacing.small)
        }
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
    availabilityStatus = "Run the check to see whether the on-device model is ready."
    isAvailable = nil
    isChecking = false // Also reset the checking state
  }

  private func availabilityMessage(for result: ModelAvailabilityResult) -> String {
    guard !result.isAvailable else {
      return "Apple Intelligence is available and the on-device model is ready."
    }

    switch result.reason {
    case .deviceNotEligible:
      return "Apple Intelligence is not available because this device is not eligible. "
        + "Foundation Lab requires iOS 26.0+, macOS 26.0+, or visionOS 26.0+ "
        + "on supported Apple Intelligence hardware."
    case .appleIntelligenceNotEnabled:
      return "Apple Intelligence is not enabled. Turn it on in Settings, then try again."
    case .modelNotReady:
      return "The on-device model is still downloading. Wait for it to finish, then check again."
    case .unknown, .none:
      return "Apple Intelligence is not available on this device right now. "
        + "This feature requires iOS 26.0+, macOS 26.0+, or visionOS 26.0+ "
        + "and a compatible Apple device with Apple Intelligence enabled."
    }
  }

  private var availabilitySymbol: String {
    if isAvailable == true {
      return "checkmark.circle.fill"
    }
    if isAvailable == false {
      return "xmark.circle.fill"
    }
    return "questionmark.circle"
  }

  private var availabilityColor: Color {
    if isAvailable == true {
      return .green
    }
    if isAvailable == false {
      return .red
    }
    return .secondary
  }
}

// MARK: - Supporting Views

private struct RequirementRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .foregroundStyle(.secondary)
        .frame(width: 24)

      Text(text)
        .font(.subheadline)
        .foregroundStyle(.primary)
    }
  }
}

#Preview {
  NavigationStack {
    ModelAvailabilityView()
  }
}
