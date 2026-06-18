//
//  Xcode27Section.swift
//  FoundationLab
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

struct Xcode27Section<Content: View>: View {
    let title: String
    let content: Content

    init(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.small)
    }
}
