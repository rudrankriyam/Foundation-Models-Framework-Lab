//
//  LibraryDetailColumn.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct LibraryDetailColumn: View {
    let item: LibraryItem?

    @Environment(ExperimentStore.self) private var experimentStore
    @Environment(NavigationCoordinator.self) private var navigationCoordinator

    var body: some View {
        content
            .navigationDestination(for: ExampleType.self) { example in
                example.destination
            }
            .navigationDestination(for: DynamicSchemaExampleType.self) { schema in
                schema.destination
            }
            .navigationDestination(for: LanguageExample.self) { language in
                language.destination
            }
            .navigationDestination(for: ExperimentLibraryCatalog.self) { catalog in
                ExperimentLibraryCatalogView(catalog: catalog)
            }
            .navigationDestination(for: Workspace.self) { workspace in
                WorkspaceView(workspace: workspace)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch item {
        case .template(let id):
            if let template = ExperimentTemplate.curatedLibrary.first(where: { $0.id == id }) {
                templateContent(template)
            } else {
                emptyState
            }
        case .savedExperiment(let id):
            if let experiment = experimentStore.savedExperiments.first(where: { $0.id == id }) {
                ExperimentPreviewView(
                    title: experiment.name.isEmpty ? String(localized: "Untitled Experiment") : experiment.name,
                    summary: experiment.summary,
                    configuration: experiment,
                    openAccessibilityHint: "Opens this saved experiment in Playground"
                ) {
                    experimentStore.load(experiment)
                    navigationCoordinator.openPlayground()
                }
            } else {
                emptyState
            }
        case nil:
            emptyState
        }
    }

    @ViewBuilder
    private func templateContent(_ template: ExperimentTemplate) -> some View {
        switch template.launch {
        case .recipe(let configuration):
            ExperimentPreviewView(
                title: template.title,
                summary: template.summary,
                configuration: configuration,
                openAccessibilityHint: "Opens this recipe in Playground"
            ) {
                experimentStore.load(configuration.asNewExperiment())
                navigationCoordinator.openPlayground()
            }
        case .guidedLab(let example):
            example.destination
        case .workshop(let catalog):
            ExperimentLibraryCatalogView(catalog: catalog)
        case .workspace(let workspace):
            WorkspaceView(workspace: workspace)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Experiment Selected",
            systemImage: "books.vertical",
            description: Text("Select a recipe, lab, or saved experiment to see it here.")
        )
    }
}
