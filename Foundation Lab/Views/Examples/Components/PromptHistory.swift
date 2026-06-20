//
//  PromptHistory.swift
//  Foundation Lab
//

import SwiftUI

struct PromptHistory: View {
    let history: [String]
    let onSelect: (String) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: toggleExpanded) {
                Label(
                    "Recent",
                    systemImage: isExpanded ? "chevron.down" : "chevron.right"
                )
                .font(.callout)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded, !history.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(history.prefix(5), id: \.self) { prompt in
                        Button(action: { onSelect(prompt) }, label: {
                            Text(prompt)
                                .font(.callout)
                                .lineLimit(2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(Spacing.small)
                                .background(.quaternary, in: .rect(cornerRadius: CornerRadius.small))
                        })
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, Spacing.small)
            }
        }
    }

    private func toggleExpanded() {
        isExpanded.toggle()
    }
}
