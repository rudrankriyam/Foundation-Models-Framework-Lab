//
//  RecipeDestinationView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct RecipeDestinationView: View {
    let example: ExampleType

    @Environment(ExperimentStore.self) private var experimentStore
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    var body: some View {
        Group {
            if let configuration {
                ContentUnavailableView {
                    Label("Opening Recipe", systemImage: "slider.horizontal.3")
                } description: {
                    Text("This example now runs as an editable Playground recipe.")
                } actions: {
                    ProgressView()
                }
                .task {
                    experimentStore.load(configuration.asNewExperiment())
                    navigationCoordinator.openPlayground()
                }
            } else {
                ContentUnavailableView {
                    Label("Recipe Unavailable", systemImage: "exclamationmark.triangle")
                } description: {
                    Text("This example does not have an editable recipe yet.")
                }
            }
        }
    }

    private var configuration: FoundationLabExperimentConfiguration? {
        ExperimentTemplate.recipeConfiguration(for: example)
    }
}
