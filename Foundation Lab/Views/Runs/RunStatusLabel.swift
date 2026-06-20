//
//  RunStatusLabel.swift
//  Foundation Lab
//

import SwiftUI

struct RunStatusLabel: View {
    let succeeded: Bool

    var body: some View {
        Label {
            Text(succeeded ? String(localized: "Succeeded") : String(localized: "Failed"))
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(succeeded ? Color.green : Color.red)
        }
        .accessibilityLabel(
            succeeded ? String(localized: "Run succeeded") : String(localized: "Run failed")
        )
    }
}

#Preview {
    VStack(alignment: .leading) {
        RunStatusLabel(succeeded: true)
        RunStatusLabel(succeeded: false)
    }
    .padding()
}
