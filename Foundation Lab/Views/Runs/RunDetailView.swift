//
//  RunDetailView.swift
//  Foundation Lab
//

import FoundationLabCore
import FoundationModelsKit
import SwiftUI

struct RunDetailView: View {
    let run: FoundationLabExperimentRun

    @Environment(ExperimentStore.self) private var store
    @Environment(NavigationCoordinator.self) private var navigationCoordinator
#if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
#endif

    var body: some View {
        content
        .navigationTitle(
            run.configuration.name.isEmpty ? String(localized: "Run Detail") : run.configuration.name
        )
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(
                    "Open in Playground",
                    systemImage: "arrow.uturn.backward.circle",
                    action: loadConfiguration
                )
                .accessibilityHint("Loads this run's exact configuration without running it")
            }
        }
    }

    @ViewBuilder
    private var content: some View {
#if os(iOS)
        if #available(iOS 27.1, *), horizontalSizeClass == .regular {
            ArrangementView {
                detailList {
                    RunDetailOverviewSection(run: run)
                    RunTranscriptSections(run: run)
                }
            } secondary: {
                detailList {
                    RunConfigurationSection(run: run)
                    RunToolsSection(tools: run.configuration.selectedTools)
                }
            }
            .arrangementViewStyle(.split)
        } else {
            combinedList
        }
#else
        combinedList
#endif
    }

    private var combinedList: some View {
        detailList {
            RunDetailOverviewSection(run: run)
            RunTranscriptSections(run: run)
            RunConfigurationSection(run: run)
            RunToolsSection(tools: run.configuration.selectedTools)
        }
    }

    private func detailList(@ViewBuilder content: () -> some View) -> some View {
        List(content: content)
#if os(iOS)
            .listStyle(.insetGrouped)
#else
            .listStyle(.inset)
#endif
    }

    private func loadConfiguration() {
        store.load(run.configuration)
        navigationCoordinator.openPlayground()
    }
}

#Preview("Successful Run") {
    let configuration = FoundationLabExperimentConfiguration(
        name: "Weather Assistant",
        prompt: "What should I wear for a walk in Cupertino?",
        instructions: "Be concise and use the weather tool.",
        kind: .toolUse,
        selectedTools: [.weather]
    )
    let run = FoundationLabExperimentRun(
        configuration: configuration,
        prompt: configuration.prompt,
        response: "A light jacket should be comfortable for your walk.",
        startedAt: .now.addingTimeInterval(-60),
        duration: 1.24,
        provider: "Apple Foundation Models",
        modelIdentifier: "SystemLanguageModel",
        tokenCount: 18
    )

    NavigationStack {
        RunDetailView(run: run)
    }
    .environment(
        ExperimentStore(
            userDefaults: UserDefaults(suiteName: "RunDetailViewPreview") ?? .standard
        )
    )
    .environment(NavigationCoordinator.shared)
}
