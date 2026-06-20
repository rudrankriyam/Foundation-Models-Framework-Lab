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
        ContentUnavailableView {
            Label("Opening Recipe", systemImage: "slider.horizontal.3")
        } description: {
            Text("This example now runs as an editable Playground recipe.")
        } actions: {
            ProgressView()
        }
        .task {
            guard let configuration = ExperimentTemplate.recipeConfiguration(for: example) else {
                return
            }
            experimentStore.load(configuration.asNewExperiment())
            navigationCoordinator.openPlayground()
        }
    }
}
