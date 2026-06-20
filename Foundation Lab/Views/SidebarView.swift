//
//  SidebarView.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/22/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var selection: TabSelection?

    var body: some View {
        List(selection: $selection) {
            Section("Workspace") {
                ForEach(TabSelection.allCases, id: \.self) { tab in
                    Label(tab.displayName, systemImage: tab.systemImage)
                        .tag(tab)
#if os(macOS)
                        .keyboardShortcut(tab.keyboardShortcut, modifiers: .command)
#endif
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Foundation Lab")
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
#endif
    }
}

extension TabSelection {
    var systemImage: String {
        switch self {
        case .library:
            return "books.vertical"
        case .playground:
            return "play.square.stack"
        case .runs:
            return "clock.arrow.circlepath"
        }
    }

#if os(macOS)
    var keyboardShortcut: KeyEquivalent {
        switch self {
        case .library: return "1"
        case .playground: return "2"
        case .runs: return "3"
        }
    }
#endif
}

#Preview {
    NavigationSplitView {
        SidebarView(selection: .constant(.library))
    } detail: {
        Text("Detail View")
    }
}
