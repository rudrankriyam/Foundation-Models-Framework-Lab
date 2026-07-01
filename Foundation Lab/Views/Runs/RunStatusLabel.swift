//
//  RunStatusLabel.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct RunStatusLabel: View {
    let status: FoundationLabExperimentRun.Status

    var body: some View {
        Label {
            Text(title)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
        .accessibilityLabel(accessibilityLabel)
    }

    private var title: String {
        switch status {
        case .succeeded:
            String(localized: "Succeeded")
        case .failed:
            String(localized: "Failed")
        case .cancelled:
            String(localized: "Cancelled")
        }
    }

    private var systemImage: String {
        switch status {
        case .succeeded:
            "checkmark.circle.fill"
        case .failed:
            "xmark.octagon.fill"
        case .cancelled:
            "stop.circle.fill"
        }
    }

    private var tint: Color {
        switch status {
        case .succeeded:
            .green
        case .failed:
            .red
        case .cancelled:
            .orange
        }
    }

    private var accessibilityLabel: String {
        switch status {
        case .succeeded:
            String(localized: "Run succeeded")
        case .failed:
            String(localized: "Run failed")
        case .cancelled:
            String(localized: "Run cancelled")
        }
    }
}

#Preview {
    VStack(alignment: .leading) {
        RunStatusLabel(status: .succeeded)
        RunStatusLabel(status: .failed)
        RunStatusLabel(status: .cancelled)
    }
    .padding()
}
