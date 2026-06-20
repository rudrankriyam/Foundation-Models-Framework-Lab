//
//  ToolExecuteButton.swift
//  Foundation Lab
//

import SwiftUI

struct ToolExecuteButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let isRunning: Bool
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        isRunning: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isRunning = isRunning
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.small) {
                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRunning)
    }
}
