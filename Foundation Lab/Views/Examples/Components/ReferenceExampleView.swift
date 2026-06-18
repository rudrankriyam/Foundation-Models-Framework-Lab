//
//  ReferenceExampleView.swift
//  FoundationLab
//
//  Created by Codex on 6/18/26.
//

import SwiftUI

/// A documentation-only example that exposes no model execution controls.
struct ReferenceExampleView<Content: View>: View {
    let title: String
    let description: String
    let codeExample: String?
    let referenceNote: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                Label {
                    VStack(alignment: .leading, spacing: Spacing.small) {
                        Text("Reference, not a live run")
                            .bold()
                        Text(referenceNote)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "book.pages")
                        .foregroundStyle(.blue)
                }
                .font(.callout)
                .accessibilityElement(children: .combine)

                content

                if let codeExample {
                    CodeDisclosure(code: codeExample)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.large)
        }
        .navigationTitle(title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .navigationSubtitle(description)
        #endif
    }
}
