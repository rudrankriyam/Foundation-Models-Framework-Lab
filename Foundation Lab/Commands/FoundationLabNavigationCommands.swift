#if os(macOS)
import SwiftUI

struct FoundationLabNavigationCommands: Commands {
    @FocusedValue(\.foundationLabNavigationCoordinator) private var navigationCoordinator

    var body: some Commands {
        CommandMenu("Navigate") {
            destinationButton(.library, shortcut: "1")
            destinationButton(.playground, shortcut: "2")
            destinationButton(.runs, shortcut: "3")
        }
    }

    private func destinationButton(
        _ destination: TabSelection,
        shortcut: KeyEquivalent
    ) -> some View {
        Button(
            destination.displayName,
            systemImage: destination.systemImage
        ) {
            navigationCoordinator?.navigate(to: destination)
        }
        .keyboardShortcut(shortcut, modifiers: .command)
        .disabled(navigationCoordinator == nil)
    }
}

extension FocusedValues {
    @Entry var foundationLabNavigationCoordinator: NavigationCoordinator?
}
#endif
