//
//  OpenToolIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/24/26.
//

import AppIntents

struct OpenToolIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Tool"
    static let description = IntentDescription("Loads a selected built-in tool recipe into Playground.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Tool")
    var tool: ToolDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$tool)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigateToTool(tool.tool)
        return .result()
    }
}
