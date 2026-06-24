//
//  OpenExampleIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/24/26.
//

import AppIntents

struct OpenExampleIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Example"
    static let description = IntentDescription("Opens a selected example from the Foundation Lab Library.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Example")
    var example: ExampleDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$example)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigateToExample(example.exampleType)
        return .result()
    }
}
