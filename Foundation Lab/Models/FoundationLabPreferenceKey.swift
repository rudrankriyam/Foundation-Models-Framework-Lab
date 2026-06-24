enum FoundationLabPreferenceKey {
    static let navigationSelection = "FoundationLab.navigation.selection"
    static let sidebarIsVisible = "FoundationLab.navigation.sidebarIsVisible"
    static let sidebarWidth = "FoundationLab.navigation.sidebarWidth"
    static let playgroundInspectorIsVisible = "FoundationLab.playground.inspectorIsVisible"
    static let playgroundInspectorWidth = "FoundationLab.playground.inspectorWidth"

    static func workspaceStage(for workspace: Workspace) -> String {
        "FoundationLab.workspace.\(workspace.rawValue).stage"
    }
}
