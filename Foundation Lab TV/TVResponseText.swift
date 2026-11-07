//
//  TVResponseText.swift
//  Foundation Lab TV
//

import SwiftUI

struct TVResponseText: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .focusable()
            }
        }
    }

    private var paragraphs: [String] {
        text.split(whereSeparator: \.isNewline).map(String.init)
    }
}
