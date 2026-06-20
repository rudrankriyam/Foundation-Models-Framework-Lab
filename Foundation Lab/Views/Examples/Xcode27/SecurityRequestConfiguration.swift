//
//  SecurityRequestConfiguration.swift
//  FoundationLab
//

import SwiftUI

struct SecurityRequestConfiguration: View {
    @Binding var retrievedContent: String
    @Binding var toolAccess: SecurityToolAccess
    @Binding var requiresApproval: Bool

    var body: some View {
        Xcode27Section(String(localized: "App policy for this turn")) {
            VStack(alignment: .leading, spacing: Spacing.large) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text("Untrusted tool output")
                        .font(.subheadline)
                        .bold()
                    TextField("Paste retrieved text", text: $retrievedContent, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                    Text("The label is metadata from your app, not a framework-provided trust classification.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Picker("Tools exposed to the model", selection: $toolAccess) {
                    ForEach(SecurityToolAccess.allCases) { access in
                        Text(access.title).tag(access)
                    }
                }

                Toggle("Require approval before external actions", isOn: $requiresApproval)
                    .disabled(!toolAccess.hasSideEffect)
            }
        }
    }
}
