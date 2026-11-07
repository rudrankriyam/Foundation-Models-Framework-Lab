//
//  AdaptiveNavigationView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import Foundation
import FoundationModels
import SwiftUI

struct AdaptiveNavigationView: View {
    @State private var languageService = LanguageService()
    @State private var columnVisibility: NavigationSplitViewVisibility
    @State private var listColumnVisibility: NavigationSplitViewVisibility
    @State private var navigationCoordinator = NavigationCoordinator()
    @State private var experimentStore = ExperimentStore()
    @State private var playgroundViewModel = ChatViewModel()
    @State private var persistenceFlushTask: Task<Void, Never>?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
#if os(macOS)
    @AppStorage(FoundationLabPreferenceKey.navigationSelection)
    private var persistedSelection = TabSelection.library.rawValue
    @AppStorage(FoundationLabPreferenceKey.sidebarIsVisible)
    private var persistedSidebarIsVisible = true
    @AppStorage(FoundationLabPreferenceKey.sidebarWidth)
    private var persistedSidebarWidth = Double(FoundationLabLayout.sidebarIdealWidth)
#endif

    var body: some View {
        Group {
#if os(iOS)
            if horizontalSizeClass == .regular {
                splitViewNavigation
            } else {
                tabBasedNavigation
            }
#else
            // macOS always uses split view
            splitViewNavigation
#endif
        }
        .environment(languageService)
        .environment(navigationCoordinator)
        .environment(experimentStore)
#if os(macOS)
        .focusedSceneValue(\.foundationLabNavigationCoordinator, navigationCoordinator)
#endif
        .onAppear {
            restorePersistedNavigationState()
            navigationCoordinator.activate()
            experimentStore.activate()
        }
        .onChange(of: navigationCoordinator.tabSelection) { oldValue, newValue in
            persistNavigationSelection(newValue)
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
                NavigationSplitView {
                    libraryList(showsPreviews: false)
                } detail: {
                    libraryDetail
                }
            }

            Tab(TabSelection.playground.displayName, systemImage: TabSelection.playground.systemImage, value: .playground) {
                NavigationStack(path: $navigationCoordinator.playgroundPath) {
                    PlaygroundView(viewModel: playgroundViewModel)
                }
            }

            Tab(TabSelection.runs.displayName, systemImage: TabSelection.runs.systemImage, value: .runs) {
                NavigationSplitView {
                    runsList
                } detail: {
                    runDetail
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
        Group {
            if navigationCoordinator.splitViewSelection == .playground {
                NavigationSplitView(columnVisibility: $columnVisibility) {
                    sidebar
                } detail: {
                    playgroundDetail
                }
            } else {
                NavigationSplitView(columnVisibility: $listColumnVisibility) {
                    sidebar
                } content: {
                    listColumn
                        .navigationSplitViewColumnWidth(
                            min: FoundationLabLayout.listColumnMinimumWidth,
                            ideal: FoundationLabLayout.listColumnIdealWidth,
                            max: FoundationLabLayout.listColumnMaximumWidth
                        )
                } detail: {
                    detailColumn
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: navigationCoordinator.splitViewSelection) { _, newValue in
            if let newValue {
                navigationCoordinator.tabSelection = newValue
            }
        }
        .onChange(of: columnVisibility) { _, newValue in
            persistSidebarVisibility(newValue != .detailOnly)
        }
        .onChange(of: listColumnVisibility) { _, newValue in
            persistSidebarVisibility(newValue != .doubleColumn && newValue != .detailOnly)
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

    private var sidebarPreferredWidth: CGFloat {
#if os(macOS)
        min(
            max(CGFloat(persistedSidebarWidth), FoundationLabLayout.sidebarMinimumWidth),
            FoundationLabLayout.sidebarMaximumWidth
        )
#else
        FoundationLabLayout.sidebarIdealWidth
#endif
    }

    private func restorePersistedNavigationState() {
#if os(macOS)
        if let selection = TabSelection(rawValue: persistedSelection) {
            navigationCoordinator.tabSelection = selection
            navigationCoordinator.splitViewSelection = selection
        }
        columnVisibility = persistedSidebarIsVisible ? .all : .detailOnly
        listColumnVisibility = persistedSidebarIsVisible ? .all : .doubleColumn
#endif
    }

    private func persistNavigationSelection(_ selection: TabSelection) {
#if os(macOS)
        persistedSelection = selection.rawValue
#endif
    }

    private func persistSidebarVisibility(_ isVisible: Bool) {
#if os(macOS)
        persistedSidebarIsVisible = isVisible
#endif
    }

    private func persistSidebarWidth(_ width: CGFloat) {
#if os(macOS)
        guard (FoundationLabLayout.sidebarMinimumWidth ... FoundationLabLayout.sidebarMaximumWidth).contains(width),
              abs(persistedSidebarWidth - Double(width)) >= 0.5 else {
            return
        }
        persistedSidebarWidth = Double(width)
#endif
    }
}

private extension AdaptiveNavigationView {
    var sidebar: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        return SidebarView(
            selection: $navigationCoordinator.splitViewSelection,
            preferredWidth: sidebarPreferredWidth,
            onWidthChange: persistSidebarWidth
        )
    }

    var playgroundDetail: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        return NavigationStack(path: $navigationCoordinator.playgroundPath) {
            PlaygroundView(viewModel: playgroundViewModel)
        }
    }

    @ViewBuilder
    var listColumn: some View {
        if navigationCoordinator.splitViewSelection == .runs {
            runsList
        } else {
            libraryList(showsPreviews: true)
        }
    }

    @ViewBuilder
    var detailColumn: some View {
        if navigationCoordinator.splitViewSelection == .runs {
            runDetail
        } else {
            libraryDetail
        }
    }

    func libraryList(showsPreviews: Bool) -> some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        return LibraryView(
            selection: $navigationCoordinator.librarySelection,
            showsPreviews: showsPreviews
        )
    }

    var libraryDetail: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        return NavigationStack(path: $navigationCoordinator.libraryPath) {
            LibraryDetailColumn(item: navigationCoordinator.librarySelection)
        }
    }

    var runsList: some View {
        @Bindable var navigationCoordinator = navigationCoordinator
        return RunsView(selection: $navigationCoordinator.runSelection)
    }

    var runDetail: some View {
        NavigationStack {
            RunDetailColumn(runID: navigationCoordinator.runSelection)
        }
    }
}

extension AdaptiveNavigationView {
    init() {
#if os(macOS)
        let isSidebarVisible = UserDefaults.standard.object(
            forKey: FoundationLabPreferenceKey.sidebarIsVisible
        ) as? Bool ?? true
        _columnVisibility = State(
            initialValue: isSidebarVisible ? .all : .detailOnly
        )
        _listColumnVisibility = State(
            initialValue: isSidebarVisible ? .all : .doubleColumn
        )
#else
        _columnVisibility = State(initialValue: .automatic)
        _listColumnVisibility = State(initialValue: .automatic)
#endif
    }
}

#Preview {
    AdaptiveNavigationView()
}
