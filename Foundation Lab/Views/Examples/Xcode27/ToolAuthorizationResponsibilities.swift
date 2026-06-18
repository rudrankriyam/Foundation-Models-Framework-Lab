//
//  ToolAuthorizationResponsibilities.swift
//  FoundationLab
//

import SwiftUI

struct ToolAuthorizationResponsibilities: View {
    var body: some View {
        Xcode27Section("Actual API boundary") {
            VStack(spacing: 0) {
                Xcode27InfoRow(
                    title: "Framework",
                    detail: "The model can generate arguments and Foundation Models can invoke the registered Tool.call method.",
                    systemImage: "apple.intelligence",
                    tint: .purple
                )
                .padding(.vertical, Spacing.medium)
                Divider()
                Xcode27InfoRow(
                    title: "Tool implementation",
                    detail: "Your code validates arguments, asks the user, and decides whether any external operation runs.",
                    systemImage: "lock.shield",
                    tint: .blue
                )
                .padding(.vertical, Spacing.medium)
            }
        }
    }
}
