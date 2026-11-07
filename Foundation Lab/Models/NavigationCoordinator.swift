//
//  NavigationCoordinator.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import FoundationLabCore
import FoundationModelsKit
import Observation
import SwiftUI

@Observable
@MainActor
final class NavigationCoordinator {
    private static let fallback = NavigationCoordinator()
    private static weak var activeCoordinator: NavigationCoordinator?

    static var shared: NavigationCoordinator {
        activeCoordinator ?? fallback
    }

    var tabSelection: TabSelection = .library
    var splitViewSelection: TabSelection? = .library
    var librarySelection: LibraryItem? {
        didSet {
            if librarySelection != oldValue {
                libraryPath = NavigationPath()
            }
        }
    }
    var libraryPath = NavigationPath()
    var playgroundPath = NavigationPath()
    var runSelection: FoundationLabExperimentRun.ID?
    private var hasPendingNavigation = false

    init() {}

    func activate() {
        if Self.activeCoordinator == nil,
           self !== Self.fallback,
           Self.fallback.hasPendingNavigation {
            tabSelection = Self.fallback.tabSelection
            splitViewSelection = Self.fallback.splitViewSelection
            librarySelection = Self.fallback.librarySelection
            libraryPath = Self.fallback.libraryPath
            playgroundPath = Self.fallback.playgroundPath
            runSelection = Self.fallback.runSelection
            Self.fallback.resetPendingNavigation()
        }

        Self.activeCoordinator = self
    }

    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
        markPendingNavigationIfNeeded()
    }

    public func navigateToExample(_ example: ExampleType) {
        if let configuration = ExperimentTemplate.recipeConfiguration(for: example) {
            openRecipe(configuration)
        } else if let template = ExperimentTemplate.template(for: .guidedLab(example)) {
            showInLibrary(.template(template.id))
        } else if ExampleType.xcode27Examples.contains(example) {
            showInLibrary(workshop: .xcode27, destination: example)
        } else {
            showInLibrary(nil, destination: example)
        }
    }

    public func navigateToTool(_ tool: FoundationLabBuiltInTool) {
        openRecipe(ExperimentTemplate.recipeConfiguration(for: tool))
    }

    public func navigateToSchema(_ schema: DynamicSchemaExampleType) {
        showInLibrary(workshop: .schemas, destination: schema)
    }

    public func navigateToLanguage(_ language: LanguageExample) {
        showInLibrary(workshop: .languages, destination: language)
    }

    public func openChat() {
        openPlayground()
    }

    public func openLibrary() {
        tabSelection = .library
        splitViewSelection = .library
        markPendingNavigationIfNeeded()
    }

    public func openPlayground() {
        tabSelection = .playground
        splitViewSelection = .playground
        markPendingNavigationIfNeeded()
    }

    public func openRuns() {
        tabSelection = .runs
        splitViewSelection = .runs
        markPendingNavigationIfNeeded()
    }

    private func openRecipe(_ configuration: FoundationLabExperimentConfiguration) {
        ExperimentStore.shared.load(configuration.asNewExperiment())
        openPlayground()
    }

    private func showInLibrary(workshop catalog: ExperimentLibraryCatalog, destination: some Hashable) {
        let workshop = ExperimentTemplate.template(for: .workshop(catalog))
        showInLibrary(workshop.map { .template($0.id) }, destination: destination)
    }

    private func showInLibrary(_ item: LibraryItem?, destination: (any Hashable)? = nil) {
        tabSelection = .library
        splitViewSelection = .library
        librarySelection = item
        libraryPath = NavigationPath()
        if let destination {
            libraryPath.append(destination)
        }
        markPendingNavigationIfNeeded()
    }

    private func markPendingNavigationIfNeeded() {
        if Self.activeCoordinator == nil, self === Self.fallback {
            hasPendingNavigation = true
        }
    }

    private func resetPendingNavigation() {
        tabSelection = .library
        splitViewSelection = .library
        librarySelection = nil
        libraryPath = NavigationPath()
        playgroundPath = NavigationPath()
        runSelection = nil
        hasPendingNavigation = false
    }
}
