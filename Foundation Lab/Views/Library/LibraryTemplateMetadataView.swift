//
//  LibraryTemplateMetadataView.swift
//  Foundation Lab
//

import SwiftUI

struct LibraryTemplateMetadataView: View {
    let launch: ExperimentLaunch

    var body: some View {
        Label(launch.displayName, systemImage: launch.systemImage)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}
