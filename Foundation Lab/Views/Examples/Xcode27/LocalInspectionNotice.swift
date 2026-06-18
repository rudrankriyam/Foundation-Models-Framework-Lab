//
//  LocalInspectionNotice.swift
//  FoundationLab
//

import SwiftUI

struct LocalInspectionNotice: View {
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text("Run inspects app policy")
                    .bold()
                Text("This deterministic preview does not call a model, classify prompt injection, or execute a tool.")
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
