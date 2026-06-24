//
//  ResultDisplay.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/29/25.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

/// Result display component
struct ResultDisplay: View {
  let result: String
  let isSuccess: Bool
  var tokenCount: Int?
  @State private var isCopied = false

  var body: some View {
    GroupBox {
      ScrollView {
        Text(formattedResult)
          .font(.body)
          .textSelection(.enabled)
          .padding(.top, Spacing.small)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(maxHeight: 300)
    } label: {
      HStack(spacing: Spacing.small) {
        Label(statusTitle, systemImage: statusImage)
          .font(.headline)
          .foregroundStyle(isSuccess ? Color.primary : Color.red)

        if let tokenCount {
          Text("\(tokenCount) tokens")
            .font(.caption)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        Spacer()

        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 4)
        }
        .accessibilityLabel(isCopied ? "Copied" : "Copy result")
        .buttonStyle(.borderless)
        .frame(
          minWidth: FoundationLabLayout.minimumTouchTarget,
          minHeight: FoundationLabLayout.minimumTouchTarget
        )
      }
    }
  }

  private var statusTitle: String {
    isSuccess ? String(localized: "Result") : String(localized: "Error")
  }

  private var statusImage: String {
    isSuccess ? "checkmark.circle" : "exclamationmark.triangle"
  }

  private var formattedResult: AttributedString {
    (try? AttributedString(markdown: result)) ?? AttributedString(result)
  }

  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = result
    UIAccessibility.post(
      notification: .announcement,
      argument: String(localized: "Result copied to the clipboard")
    )
    #elseif os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(result, forType: .string)
    #endif

    isCopied = true
    Task {
      try? await Task.sleep(for: .seconds(2))
      guard !Task.isCancelled else { return }
      isCopied = false
    }
  }
}
