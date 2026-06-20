//
//  LibraryEmptyState.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct LibraryEmptyState: View {
    let searchText: String
    let selectedLevel: FoundationLabExperimentLevel?
    let showAllLevels: () -> Void

    var body: some View {
        if searchText.isEmpty, let selectedLevel {
            ContentUnavailableView {
                Label(
                    "No \(selectedLevel.displayName) Experiments",
                    systemImage: selectedLevel.systemImage
                )
            } description: {
                Text("Choose another experience level to see more recipes.")
            } actions: {
                Button("Show All Levels", action: showAllLevels)
            }
        } else {
            ContentUnavailableView.search
        }
    }
}

#Preview {
    LibraryEmptyState(searchText: "", selectedLevel: .expert) {}
}
