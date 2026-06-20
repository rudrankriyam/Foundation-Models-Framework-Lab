//
//  NavigationCoordinator.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import FoundationLabCore
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

    init() {}

    func activate() {
        Self.activeCoordinator = self
    }

    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }

    public func navigateToExample(_ example: ExampleType) {
        if let configuration = ExperimentTemplate.recipeConfiguration(for: example) {
            openRecipe(configuration)
        } else if example == .chat {
            openPlayground()
        } else {
            tabSelection = .library
            splitViewSelection = .library
            libraryPath = NavigationPath()
            libraryPath.append(example)
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
    }

    public func navigateToLanguage(_ language: LanguageExample) {
        tabSelection = .library
        splitViewSelection = .library
        libraryPath = NavigationPath()
        libraryPath.append(language)
    }

    public func openChat() {
        openPlayground()
    }

    public func openLibrary() {
        tabSelection = .library
        splitViewSelection = .library
    }

    public func openPlayground() {
        tabSelection = .playground
        splitViewSelection = .playground
    }

    public func openRuns() {
        tabSelection = .runs
        splitViewSelection = .runs
    }

    private func openRecipe(_ configuration: FoundationLabExperimentConfiguration) {
        ExperimentStore.shared.load(configuration.asNewExperiment())
        openPlayground()
    }
}
