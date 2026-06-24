//
//  LibraryView.swift
//  Foundation Lab
//

import FoundationLabCore
import SwiftUI

struct LibraryView: View {
    @Environment(ExperimentStore.self) private var experimentStore
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var searchText = ""
    @State private var showsSettings = false
    @State private var experimentPendingDeletion: FoundationLabExperimentConfiguration?

    var body: some View {
        Group {
            if !hasResults {
                ContentUnavailableView.search
            } else {
                libraryList
            }
        }
        .navigationTitle("Library")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #else
        .navigationSubtitle("Ready-made recipes and saved experiments")
        #endif
        .searchable(
            text: $searchText,
            prompt: "Search experiments and tools"
        )
#if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                SettingsToolbarButton(isPresented: $showsSettings)
            }
        }
#endif
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .confirmationDialog(
            "Delete this saved experiment?",
            isPresented: deletionConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Delete Experiment", role: .destructive, action: confirmDeletion)
        } message: {
            if let experimentPendingDeletion {
                Text("\(experimentPendingDeletion.name) will be permanently deleted. Recorded runs are not affected.")
            }
        }
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
}

private extension LibraryView {
    private var libraryList: some View {
        List {
            if !filteredSavedExperiments.isEmpty {
                Section("My Experiments") {
                    ForEach(filteredSavedExperiments) { experiment in
                        Button(
                            action: { openSavedExperiment(experiment) },
                            label: { SavedExperimentRow(experiment: experiment) }
                        )
                        .buttonStyle(.plain)
                        .accessibilityHint("Opens this saved experiment in Playground")
                        .swipeActions {
                            Button("Delete Experiment", systemImage: "trash", role: .destructive) {
                                experimentPendingDeletion = experiment
                            }
                        }
                    }
                }
            }

            ForEach(visibleTracks) { track in
                Section(track.title) {
                    ForEach(filteredTemplates(in: track)) { template in
                        templateDestination(template)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.plain)
        #else
        .listStyle(.inset)
        #endif
    }

    @ViewBuilder
    private func templateDestination(_ template: ExperimentTemplate) -> some View {
        switch template.launch {
        case .recipe(let configuration):
            Button(
                action: { openTemplate(configuration) },
                label: { LibraryTemplateRow(template: template) }
            )
            .buttonStyle(.plain)
            .accessibilityHint("Opens this recipe in Playground")
        case .guidedLab(let example):
            NavigationLink(value: example) {
                LibraryTemplateRow(template: template)
            }
        case .workshop(let catalog):
            NavigationLink(value: catalog) {
                LibraryTemplateRow(template: template)
            }
        case .workspace(let workspace):
            NavigationLink(value: workspace) {
                LibraryTemplateRow(template: template)
            }
        }
    }

    private var hasResults: Bool {
        !filteredTemplates.isEmpty || !filteredSavedExperiments.isEmpty
    }

    private var visibleTracks: [ExperimentTrack] {
        ExperimentTrack.allCases.filter { !filteredTemplates(in: $0).isEmpty }
    }

    private var filteredTemplates: [ExperimentTemplate] {
        ExperimentTemplate.curatedLibrary.filter(matches)
    }

    private var filteredSavedExperiments: [FoundationLabExperimentConfiguration] {
        experimentStore.savedExperiments.filter(matches)
    }

    private func filteredTemplates(in track: ExperimentTrack) -> [ExperimentTemplate] {
        filteredTemplates.filter { $0.track == track }
    }

    private func matches(_ template: ExperimentTemplate) -> Bool {
        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        let searchableText = [
            template.title,
            template.summary,
            template.launch.displayName,
            template.track.title,
            template.track.subtitle
        ] + template.keywords

        return searchableText.contains { $0.localizedStandardContains(query) }
    }

    private func matches(_ experiment: FoundationLabExperimentConfiguration) -> Bool {
        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        let searchableText = [
            experiment.name,
            experiment.summary,
            experiment.prompt,
            experiment.instructions,
            experiment.kind.displayName
        ] + experiment.selectedTools.map(\.displayName)

        return searchableText.contains { $0.localizedStandardContains(query) }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func openSavedExperiment(_ experiment: FoundationLabExperimentConfiguration) {
        experimentStore.load(experiment)
        navigationCoordinator.openPlayground()
    }

    private var deletionConfirmationBinding: Binding<Bool> {
        Binding(
            get: { experimentPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    experimentPendingDeletion = nil
                }
            }
        )
    }

    private func confirmDeletion() {
        guard let experimentPendingDeletion else { return }
        experimentStore.deleteSavedExperiment(id: experimentPendingDeletion.id)
        self.experimentPendingDeletion = nil
    }

    private func openTemplate(_ configuration: FoundationLabExperimentConfiguration) {
        experimentStore.load(configuration.asNewExperiment())
        navigationCoordinator.openPlayground()
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .environment(ExperimentStore.shared)
    .environment(NavigationCoordinator.shared)
}
