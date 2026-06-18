//
//  ToolApprovalReview.swift
//  FoundationLab
//

import SwiftUI

struct ToolApprovalReview: View {
    let decision: ToolApprovalDecision
    let approve: () -> Void
    let deny: () -> Void

    var body: some View {
        Xcode27Section("Proposed tool action") {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Xcode27StatusRow(
                    title: "Authorization",
                    value: decision.title,
                    systemImage: decision.icon,
                    tint: decision.tint
                )

                Xcode27KeyValueList(items: [
                    ("Tool", "sendMessage"),
                    ("Recipient", "Client"),
                    ("Effect", "External message"),
                    ("Executed", "No")
                ])

                Text(decision.detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if decision.awaitsDecision {
                    HStack(spacing: Spacing.small) {
                        Button("Deny", systemImage: "xmark", action: deny)
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)

                        Button("Approve demo", systemImage: "checkmark", action: approve)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}
