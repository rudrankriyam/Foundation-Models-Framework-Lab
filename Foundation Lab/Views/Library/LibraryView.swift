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
    @State private var selectedLevel: FoundationLabExperimentLevel?
    @State private var showsSettings = false

    var body: some View {
        Group {
            if !hasResults {
                LibraryEmptyState(
                    searchText: trimmedSearchText,
                    selectedLevel: selectedLevel,
                    showAllLevels: showAllLevels
                )
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                levelFilter
#if os(iOS)
                Button("Settings", systemImage: "gear") {
                    showsSettings = true
                }
#endif
            }
        }
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .navigationDestination(for: ExampleType.self) { example in
            example.destination
        }
        .navigationDestination(for: ToolExample.self) { tool in
            tool.destination
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
                            Button("Delete", systemImage: "trash", role: .destructive) {
                                deleteSavedExperiment(experiment)
                            }
                        }
                    }
                }
            }

            if shouldShowLibraryIntroduction {
                Section {
                    Text("Start with a working recipe, change one thing, then save the result as your own experiment.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(
                            "Start with a working recipe. Change one thing. Then save the result as your own experiment."
                        )
                }
            }

            ForEach(visibleTracks) { track in
                Section {
                    ForEach(filteredTemplates(in: track)) { template in
                        templateDestination(template)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: Spacing.xSmall) {
                        Text(track.title)
                        Text(track.subtitle)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textCase(nil)
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    @ViewBuilder
    private func templateDestination(_ template: ExperimentTemplate) -> some View {
        switch template.launch {
        case .playground(let configuration):
            Button(
                action: { openTemplate(configuration) },
                label: { LibraryTemplateRow(template: template) }
            )
            .buttonStyle(.plain)
            .accessibilityHint("Opens this recipe in Playground")
        case .example(let example):
            NavigationLink(value: example) {
                LibraryTemplateRow(template: template)
            }
        case .tool(let tool):
            NavigationLink(value: tool) {
                LibraryTemplateRow(template: template)
            }
        case .catalog(let catalog):
            NavigationLink(value: catalog) {
                LibraryTemplateRow(template: template)
            }
        }
    }

    private var levelFilter: some View {
        Menu {
            Picker("Experience Level", selection: $selectedLevel) {
                Text("All Levels")
                    .tag(nil as FoundationLabExperimentLevel?)

                ForEach(FoundationLabExperimentLevel.allCases, id: \.self) { level in
                    Label(level.displayName, systemImage: level.systemImage)
                        .tag(level as FoundationLabExperimentLevel?)
                }
            }
        } label: {
            Label(
                selectedLevel?.displayName ?? "All Levels",
                systemImage: selectedLevel?.systemImage ?? "line.3.horizontal.decrease"
            )
        }
        .accessibilityLabel("Filter by experience level")
    }

    private var isShowingAllTemplates: Bool {
        trimmedSearchText.isEmpty && selectedLevel == nil
    }

    private var shouldShowLibraryIntroduction: Bool {
        isShowingAllTemplates && experimentStore.savedExperiments.isEmpty
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
        if let selectedLevel, template.level != selectedLevel {
            return false
        }

        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        let searchableText = [
            template.title,
            template.summary,
            template.level.displayName,
            template.track.title,
            template.track.subtitle
        ] + template.keywords

        return searchableText.contains { $0.localizedStandardContains(query) }
    }

    private func matches(_ experiment: FoundationLabExperimentConfiguration) -> Bool {
        if let selectedLevel, selectedLevel != experiment.level {
            return false
        }

        let query = trimmedSearchText
        guard !query.isEmpty else { return true }

        let searchableText = [
            experiment.name,
            experiment.summary,
            experiment.prompt,
            experiment.instructions,
            experiment.level.displayName,
            experiment.kind.displayName
        ] + experiment.selectedTools.map(\.displayName)

        return searchableText.contains { $0.localizedStandardContains(query) }
    }

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func showAllLevels() {
        selectedLevel = nil
    }

    private func openSavedExperiment(_ experiment: FoundationLabExperimentConfiguration) {
        experimentStore.load(experiment)
        navigationCoordinator.openPlayground()
    }

    private func deleteSavedExperiment(_ experiment: FoundationLabExperimentConfiguration) {
        experimentStore.deleteSavedExperiment(id: experiment.id)
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
