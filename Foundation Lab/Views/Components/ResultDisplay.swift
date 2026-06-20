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
    VStack(alignment: .leading, spacing: Spacing.small) {
      HStack {
        Label(statusTitle, systemImage: statusImage)
          .font(.headline)
          .foregroundStyle(statusColor)

        if let tokenCount {
          Text("\(tokenCount) tokens")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary, in: .capsule)
        }

        Spacer()

        Button(action: copyToClipboard) {
          Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
            .font(.callout)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, 4)
        }
        .accessibilityLabel(isCopied ? "Copied" : "Copy result")
        .buttonStyle(.glass)
      }

      ScrollView {
        Text(formattedResult)
          .font(.body)
          .textSelection(.enabled)
          .padding(Spacing.medium)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(.quaternary, in: .rect(cornerRadius: CornerRadius.medium))
      }
      .frame(maxHeight: 300)
    }
  }

  private var statusTitle: String {
    isSuccess ? String(localized: "Result") : String(localized: "Error")
  }

  private var statusImage: String {
    isSuccess ? "checkmark.circle" : "exclamationmark.triangle"
  }

  private var statusColor: Color {
    isSuccess ? .secondary : .red
  }

  private var formattedResult: AttributedString {
    (try? AttributedString(markdown: result)) ?? AttributedString(result)
  }

  private func copyToClipboard() {
    #if os(iOS)
    UIPasteboard.general.string = result
    UIAccessibility.post(notification: .announcement, argument: "Result copied to clipboard")
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
