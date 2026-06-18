//
//  Xcode27KeyValueList.swift
//  FoundationLab
//
//  Created by Codex on 6/17/26.
//

import SwiftUI

struct Xcode27KeyValueList: View {
    let items: [(String, String)]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]

                LabeledContent(item.0) {
                    Text(item.1)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
                .font(.callout)
                .padding(.vertical, Spacing.small)

                if index < items.index(before: items.endIndex) {
                    Divider()
                }
            }
        }
    }
}
