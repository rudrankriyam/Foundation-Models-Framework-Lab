//
//  SecurityResponsibilitiesView.swift
//  FoundationLab
//

import SwiftUI

struct SecurityResponsibilitiesView: View {
    var body: some View {
        Xcode27Section("Who enforces what") {
            VStack(spacing: 0) {
                Xcode27InfoRow(
                    title: "Foundation Models framework",
                    detail: "Applies built-in guardrails to model input and output, invokes registered tools, "
                        + "and records tool calls and outputs in the transcript.",
                    systemImage: "apple.intelligence",
                    tint: .purple
                )
                .padding(.vertical, Spacing.medium)

                Divider()

                Xcode27InfoRow(
                    title: "Your app",
                    detail: "Chooses which tools exist, separates untrusted data, validates generated arguments, "
                        + "requests authorization, and controls every side effect.",
                    systemImage: "app.badge.checkmark",
                    tint: .blue
                )
                .padding(.vertical, Spacing.medium)
            }
        }
    }
}
