//
//  RunToolsSection.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct RunToolsSection: View {
    let tools: [FoundationLabBuiltInTool]

    var body: some View {
        Section("Tools") {
            if tools.isEmpty {
                Label("No tools selected", systemImage: "wrench.and.screwdriver")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(tools) { tool in
                    Label {
                        VStack(alignment: .leading, spacing: Spacing.xSmall) {
                            Text(LocalizedStringKey(tool.displayName))
                            Text(tool.summary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: tool.systemImage)
                    }
                }
            }
        }
    }
}
