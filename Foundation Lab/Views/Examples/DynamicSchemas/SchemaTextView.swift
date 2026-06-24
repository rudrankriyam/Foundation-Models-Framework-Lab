//
//  SchemaTextView.swift
//  Foundation Lab
//

import SwiftUI

struct SchemaTextView: View {
    let title: LocalizedStringKey
    let text: String
    var systemImage = "curlybraces"
    var maximumHeight: CGFloat = 300
    var isError = false
    var usesMonospacedFont = true

    var body: some View {
        GroupBox {
            ScrollView {
                Text(text)
                    .font(usesMonospacedFont ? .system(.callout, design: .monospaced) : .callout)
                    .foregroundStyle(isError ? Color.red : Color.primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, Spacing.small)
            }
            .frame(maxHeight: maximumHeight)
        } label: {
            Label(title, systemImage: systemImage)
                .font(.headline)
        }
    }
}

#Preview {
    SchemaTextView(
        title: "Generated Data",
        text: """
        {
          "name": "Foundation Lab"
        }
        """
    )
    .padding()
}
