//
//  LibraryTemplateMetadataView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct LibraryTemplateMetadataView: View {
    let launch: ExperimentLaunch
    let level: FoundationLabExperimentLevel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.medium) {
                Label(launch.displayName, systemImage: launch.systemImage)
                Label(level.displayName, systemImage: level.systemImage)
            }

            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Label(launch.displayName, systemImage: launch.systemImage)
                Label(level.displayName, systemImage: level.systemImage)
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
