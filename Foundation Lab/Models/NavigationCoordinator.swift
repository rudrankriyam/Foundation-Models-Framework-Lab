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
    var libraryPath = NavigationPath()
    var playgroundPath = NavigationPath()
    var runsPath = NavigationPath()
    private var hasPendingNavigation = false

    init() {}

    func activate() {
        if Self.activeCoordinator == nil,
           self !== Self.fallback,
           Self.fallback.hasPendingNavigation {
            tabSelection = Self.fallback.tabSelection
            splitViewSelection = Self.fallback.splitViewSelection
            libraryPath = Self.fallback.libraryPath
            playgroundPath = Self.fallback.playgroundPath
            runsPath = Self.fallback.runsPath
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
        } else {
            tabSelection = .library
            splitViewSelection = .library
            libraryPath = NavigationPath()
            libraryPath.append(example)
            markPendingNavigationIfNeeded()
        }
    }

    public func navigateToTool(_ tool: FoundationLabBuiltInTool) {
        openRecipe(ExperimentTemplate.recipeConfiguration(for: tool))
    }

    public func navigateToSchema(_ schema: DynamicSchemaExampleType) {
        tabSelection = .library
        splitViewSelection = .library
        libraryPath = NavigationPath()
        libraryPath.append(schema)
        markPendingNavigationIfNeeded()
    }

    public func navigateToLanguage(_ language: LanguageExample) {
        tabSelection = .library
        splitViewSelection = .library
        libraryPath = NavigationPath()
        libraryPath.append(language)
        markPendingNavigationIfNeeded()
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

    private func markPendingNavigationIfNeeded() {
        if Self.activeCoordinator == nil, self === Self.fallback {
            hasPendingNavigation = true
        }
    }

    private func resetPendingNavigation() {
        tabSelection = .library
        splitViewSelection = .library
        libraryPath = NavigationPath()
        playgroundPath = NavigationPath()
        runsPath = NavigationPath()
        hasPendingNavigation = false
    }
}
