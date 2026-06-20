//
//  SecurityResponsibilitiesView.swift
//  FoundationLab
//

import SwiftUI

struct SecurityResponsibilitiesView: View {
    var body: some View {
        Xcode27Section(String(localized: "Who enforces what")) {
            VStack(spacing: 0) {
                Xcode27InfoRow(
                    title: String(localized: "Foundation Models framework"),
                    detail: String(
                        localized: """
                        Applies built-in guardrails to model input and output, invokes registered tools, and records tool calls and \
                        outputs in the transcript.
                        """
                    ),
                    systemImage: "apple.intelligence",
                    tint: .purple
                )
                .padding(.vertical, Spacing.medium)

                Divider()

                Xcode27InfoRow(
                    title: String(localized: "Your app"),
                    detail: String(
                        localized: """
                        Chooses which tools exist, separates untrusted data, validates generated arguments, requests authorization, \
                        and controls every side effect.
                        """
                    ),
                    systemImage: "app.badge.checkmark",
                    tint: .blue
                )
                .padding(.vertical, Spacing.medium)
            }
        }
    }
}
