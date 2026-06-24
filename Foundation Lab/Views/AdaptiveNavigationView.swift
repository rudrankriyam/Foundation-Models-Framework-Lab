//
//  AdaptiveNavigationView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI
import FoundationModels

struct AdaptiveNavigationView: View {
    @State private var languageService = LanguageService()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var navigationCoordinator = NavigationCoordinator()
    @State private var experimentStore = ExperimentStore()
    @State private var playgroundViewModel = ChatViewModel()
    @State private var persistenceFlushTask: Task<Void, Never>?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
#if os(iOS)
            if horizontalSizeClass == .compact {
                // iPhone or iPad in compact width (portrait on smaller iPads)
                tabBasedNavigation
            } else {
                // iPad in regular width (landscape or larger iPads)
                splitViewNavigation
            }
#else
            // macOS always uses split view
            splitViewNavigation
#endif
        }
        .environment(languageService)
        .environment(navigationCoordinator)
        .environment(experimentStore)
        .onAppear {
            navigationCoordinator.activate()
            experimentStore.activate()
        }
        .onChange(of: navigationCoordinator.tabSelection) { oldValue, newValue in
            if oldValue == .playground, newValue != .playground {
                playgroundViewModel.suspendVoiceMode()
            }
        }
        .onChange(of: scenePhase) { _, newValue in
            if newValue == .active {
                navigationCoordinator.activate()
                experimentStore.activate()
            } else {
                playgroundViewModel.suspendVoiceMode()
                schedulePersistenceFlush()
            }
        }
        .onDisappear {
            playgroundViewModel.suspendVoiceMode()
            schedulePersistenceFlush()
        }
        .alert(
            "Couldn’t Save Changes",
            isPresented: persistenceAlertBinding
        ) {
            Button("Try Again") {
                Task {
                    await experimentStore.retryPersistence()
                }
            }
            Button("Keep Working", role: .cancel, action: experimentStore.clearPersistenceError)
        } message: {
            if let message = experimentStore.persistenceErrorMessage {
                Text(message)
            } else {
                Text("Your latest changes are still available in this session. Try saving again.")
            }
        }
    }

    @ViewBuilder
    private var tabBasedNavigation: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        TabView(selection: $navigationCoordinator.tabSelection) {
            Tab(TabSelection.library.displayName, systemImage: TabSelection.library.systemImage, value: .library) {
                NavigationStack(path: $navigationCoordinator.libraryPath) {
                    LibraryView()
                }
            }

            Tab(TabSelection.playground.displayName, systemImage: TabSelection.playground.systemImage, value: .playground) {
                NavigationStack(path: $navigationCoordinator.playgroundPath) {
                    PlaygroundView(viewModel: playgroundViewModel)
                }
            }

            Tab(TabSelection.runs.displayName, systemImage: TabSelection.runs.systemImage, value: .runs) {
                NavigationStack(path: $navigationCoordinator.runsPath) {
                    RunsView()
                }
            }
        }
#if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
#endif
        .onChange(of: navigationCoordinator.tabSelection) { _, newValue in
            navigationCoordinator.splitViewSelection = newValue
        }
    }

    @ViewBuilder
    private var splitViewNavigation: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        NavigationSplitView(
            columnVisibility: $columnVisibility
        ) {
            SidebarView(selection: $navigationCoordinator.splitViewSelection)
        } detail: {
            detailView
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: navigationCoordinator.splitViewSelection) { _, newValue in
            if let newValue {
                navigationCoordinator.tabSelection = newValue
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        switch navigationCoordinator.splitViewSelection ?? .library {
        case .library:
            NavigationStack(path: $navigationCoordinator.libraryPath) {
                LibraryView()
            }
        case .playground:
            NavigationStack(path: $navigationCoordinator.playgroundPath) {
                PlaygroundView(viewModel: playgroundViewModel)
            }
        case .runs:
            NavigationStack(path: $navigationCoordinator.runsPath) {
                RunsView()
            }
        }
    }

    private var persistenceAlertBinding: Binding<Bool> {
        Binding(
            get: { experimentStore.persistenceErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    experimentStore.clearPersistenceError()
                }
            }
        )
    }

    private func schedulePersistenceFlush() {
        persistenceFlushTask?.cancel()
        persistenceFlushTask = Task {
            _ = await experimentStore.flushPendingPersistence()
        }
    }
}

#Preview {
    AdaptiveNavigationView()
}
