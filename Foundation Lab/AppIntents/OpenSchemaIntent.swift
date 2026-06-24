//
//  OpenSchemaIntent.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 1/24/26.
//

import AppIntents

struct OpenSchemaIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Schema Example"
    static let description = IntentDescription("Opens a selected dynamic schema lab in Foundation Lab.")
    static let supportedModes: IntentModes = .foreground

    @Parameter(title: "Schema Example")
    var schema: SchemaDestination

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$schema)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        NavigationCoordinator.shared.navigateToSchema(schema.schemaExample)
        return .result()
    }
}
