//
//  ToolApprovalNotice.swift
//  FoundationLab
//

import SwiftUI

struct ToolApprovalNotice: View {
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Local authorization demo")
                    .bold()
                Text(
                    String(
                        localized: """
                        Run does not call the model and this example has no message transport. It demonstrates the app boundary \
                        around Tool.call.
                        """
                    )
                )
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
        }
        .font(.callout)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
