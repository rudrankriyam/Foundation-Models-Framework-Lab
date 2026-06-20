//
//  PermissiveGuardrailsToggle.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 12/02/2025.
//

import SwiftUI

struct PermissiveGuardrailsToggle: View {
    @Binding var isEnabled: Bool

    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Permissive Content Transformations")
                    .font(.callout)
                    .foregroundStyle(.primary)

                Text("Allow potentially unsafe content for text transformations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(Color.gray.opacity(0.1))
        .clipShape(.rect(cornerRadius: 12))
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var isEnabled = false

        var body: some View {
            VStack(spacing: 20) {
                PermissiveGuardrailsToggle(isEnabled: $isEnabled)
                    .padding()
            }
        }
    }

    return PreviewWrapper()
}
