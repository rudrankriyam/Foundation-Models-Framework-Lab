//
//  RunsView.swift
//  Foundation Lab
//

import Foundation
import FoundationLabCore
import SwiftUI

struct RunsView: View {
    @Environment(ExperimentStore.self) private var store
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
    @State private var searchText = ""
    @State private var showsSettings = false

    var body: some View {
        Group {
            if store.runs.isEmpty {
                emptyState
            } else if filteredRuns.isEmpty {
                ContentUnavailableView.search
            } else {
                runsList
            }
        }
        .navigationTitle("Runs")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #else
        .navigationSubtitle("Exact configurations, output, and timing")
        #endif
        .searchable(text: $searchText, prompt: "Search runs")
        .navigationDestination(for: UUID.self) { runID in
            if let run = store.runs.first(where: { $0.id == runID }) {
                RunDetailView(run: run)
            } else {
                ContentUnavailableView(
                    "Run Not Found",
                    systemImage: "questionmark.folder",
                    description: Text("This run may have been deleted in another window.")
                )
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem(placement: .primaryAction) {
                SettingsToolbarButton(isPresented: $showsSettings)
            }
#endif
            if !store.runs.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    ClearRunsButton()
                }
            }
        }
#if os(iOS)
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView()
            }
        }
#endif
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Runs Yet", systemImage: "clock.arrow.circlepath")
        } description: {
            Text("Run an experiment to keep its output, timing, and exact configuration here.")
        } actions: {
            Button(
                "Open Playground",
                systemImage: "play.fill",
                action: navigationCoordinator.openPlayground
            )
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private var runsList: some View {
        List {
            ForEach(groupedRuns, id: \.date) { group in
                Section {
                    ForEach(group.runs) { run in
                        NavigationLink(value: run.id) {
                            RunRowView(run: run)
                        }
                        .swipeActions {
                            Button(
                                "Delete Run",
                                systemImage: "trash",
                                role: .destructive
                            ) {
                                deleteRun(run)
                            }
                        }
                        .contextMenu {
                            Button(
                                "Delete Run",
                                systemImage: "trash",
                                role: .destructive
                            ) {
                                deleteRun(run)
                            }
                        }
                    }
                } header: {
                    Text(group.date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                }
            }
        }
        #if os(iOS)
        .listStyle(.plain)
        #else
        .listStyle(.inset)
        #endif
    }

    private var filteredRuns: [FoundationLabExperimentRun] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return store.runs
        }

        return store.runs.filter { run in
            let searchableValues = [
                run.configuration.name,
                run.configuration.summary,
                run.configuration.kind.displayName,
                run.prompt,
                run.response,
                run.errorMessage ?? "",
                run.provider,
                run.modelIdentifier,
                run.configuration.selectedTools.map(\.displayName).joined(separator: " ")
            ]
            return searchableValues.contains { $0.localizedStandardContains(query) }
        }
    }

    private var groupedRuns: [(date: Date, runs: [FoundationLabExperimentRun])] {
        let grouped = Dictionary(grouping: filteredRuns) { run in
            Calendar.current.startOfDay(for: run.startedAt)
        }

        return grouped
            .map { date, runs in
                (date: date, runs: runs.sorted { $0.startedAt > $1.startedAt })
            }
            .sorted { $0.date > $1.date }
    }

    private func deleteRun(_ run: FoundationLabExperimentRun) {
        store.deleteRun(id: run.id)
    }
}

#Preview("Empty Runs") {
    RunsView()
        .environment(
            ExperimentStore(
                userDefaults: UserDefaults(suiteName: "RunsViewPreview") ?? .standard
            )
        )
        .environment(NavigationCoordinator.shared)
}
