//
//  ToolExecuteButton.swift
//  Foundation Lab
//

import SwiftUI

struct ToolExecuteButton: View {
    let title: LocalizedStringKey
    let systemImage: String?
    let isRunning: Bool
    let stopAction: (() -> Void)?
    let action: () -> Void

    init(
        _ title: LocalizedStringKey,
        systemImage: String? = nil,
        isRunning: Bool = false,
        stopAction: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.isRunning = isRunning
        self.stopAction = stopAction
        self.action = action
    }

    private var isStoppable: Bool {
        isRunning && stopAction != nil
    }

    var body: some View {
        Button {
            if isRunning, let stopAction {
                stopAction()
            } else {
                action()
            }
        } label: {
            HStack(spacing: Spacing.small) {
                if isStoppable {
                    Image(systemName: "stop.fill")
                } else if isRunning {
                    ProgressView()
                        .controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }

                Text(isStoppable ? "Stop" : title)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(isRunning && !isStoppable)
    }
}
