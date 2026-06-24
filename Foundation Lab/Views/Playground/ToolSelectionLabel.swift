//
//  ToolSelectionLabel.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct ToolSelectionLabel: View {
    let tool: FoundationLabBuiltInTool

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(LocalizedStringKey(tool.displayName))
                    .foregroundStyle(.primary)
                Text(LocalizedStringKey(tool.summary))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: tool.systemImage)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: FoundationLabLayout.minimumTouchTarget)
        .contentShape(.rect)
    }
}
