//
//  RunStatusLabel.swift
//  Foundation Lab
//

import SwiftUI

struct RunStatusLabel: View {
    let succeeded: Bool

    var body: some View {
        Label {
            Text(succeeded ? "Succeeded" : "Failed")
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(succeeded ? Color.green : Color.red)
        }
        .accessibilityLabel(succeeded ? "Run succeeded" : "Run failed")
    }
}

#Preview {
    VStack(alignment: .leading) {
        RunStatusLabel(succeeded: true)
        RunStatusLabel(succeeded: false)
    }
    .padding()
}
